from collections import namedtuple
import itertools
import datetime
import multiprocessing
import inspect
import json
import os
from timeit import default_timer

import vertica_python
import pandas as pd
from cached_property import cached_property
import yaml
import psycopg2
import psycopg2.extras
import cerberus

from log_helper import configure_logger
from ab_significance.significance import ObservationsStats, CompareObservations

DFT_VERTICA_AUTH_FILE = '~/vertica_auth.json'

with open(os.path.expanduser(DFT_VERTICA_AUTH_FILE),  'r') as f:
    auth = json.load(f)

RESULT_COLUMNS = [
    'ab_test_id',
    'period_id',
    'metric_id',
    'metric',
    'start_date',
    'calc_date',
    'split_group_id',
    'control_split_group_id',
    'class_name',
    'method',
    'stat_func',
    'comp_func',
    'null_value',
    'alternative',
    'alpha',
    'is_pivotal',
    'n_iters',
    'mean',
    'std',
    'n_obs',
    'p_value',
    'test_statistic',
    'lower_bound',
    'upper_bound',
    'elapsed_seconds'
]

ITER_COLUMNS = RESULT_COLUMNS[:17]

METRIC_PARAMS_COLUMS = RESULT_COLUMNS[8:17]

Iter = namedtuple('Iter', ITER_COLUMNS)
Iter.__new__.__defaults__ = (None,) * len(Iter._fields)
MetricParams = namedtuple('MetricParams', METRIC_PARAMS_COLUMS)
MetricParams.__new__.__defaults__ = (None,) * len(MetricParams._fields)
IterResult = namedtuple('IterResult', RESULT_COLUMNS)
IterResult.__new__.__defaults__ = (None,) * len(IterResult._fields)

USE_LOCAL = True

EVENTS_FILENAME = 'events'
OBSERVATIONS_FILENAME = 'observations'
METRICS_FILENAME = 'metrics'
PARAMS_FILENAME = 'params_default'


def _get_config(filename):
    if USE_LOCAL:
        url = '../config/' + filename + '.yaml'
        with open(url, 'r') as f:
            return yaml.load(f)
    else:
        url = 'http://stash.msk.avito.ru/projects/BI/repos/ab-metrics/raw/config/' + filename + '.yaml'
        with requests.get(url) as r:
            return yaml.load(r.text)


DEFAULT_TEMPLATE = 'single_observation_sum'


def _get_template(filename):
    if USE_LOCAL:
        url = '../templates/' + filename + '.sql'
        with open(url, 'r') as f:
            return f.read()
    else:
        url = 'http://stash.msk.avito.ru/projects/BI/repos/ab-metrics/raw/templates/' + filename + '.sql'
        with requests.get(url) as r:
            return f.read()


def connect_vertica():
    conn_info = {
        'host': 'avi-dwh24',
        'port': 5433,
        'database': 'DWH',
        # 10 minutes timeout on queries
        'read_timeout': 3600,
        # default throw error on invalid UTF-8 results
        # 'unicode_error': 'strict',
        # SSL is disabled by default
        # 'ssl': False,
        # 'connection_timeout': 20
        # connection timeout is not enabled by default
    }
    conn_info.update(auth)
    return vertica_python.connect(**conn_info)


def connect_postgre():
    """Connects to the specific database."""
    return psycopg2.connect(dbname='ab_config',
                            user='ab_configurator',
                            password='ab_configurator',
                            host='ab-central',
                            port=5432)

logger = configure_logger(logger_name='metrics_calc', log_dir='log')


def get_df_from_vertica(sql):
    with connect_vertica() as vcon:
        return pd.read_sql(sql, vcon)


class AbMetricsIters:

    def __init__(self):

        scripts = [
            'sql_ab_test',
            'sql_ab_metric',
            'sql_ab_period',
            'sql_ab_split_group',
            'sql_ab_split_group_pair',
        ]

        sqls = [self._get_sql(sql_script_name) for sql_script_name in scripts]

        with multiprocessing.Pool(5) as pool:
            dfs = pool.map(get_df_from_vertica, sqls)

        for script, df in zip(scripts, dfs):
            setattr(self, 'df' + script[3:], df)

        with connect_postgre() as pgcon:
            self.df_ab_metric_params = pd.read_sql(self._get_sql('sql_pg_ab_metric_params'), pgcon)

        self.metrics = _get_config(METRICS_FILENAME)

    @staticmethod
    def _get_sql(script_name):
        url = '../metrics_calc/scripts.sql'
        with open(url, 'r') as f:
            return yaml.load(f)[script_name]

    @staticmethod
    def get_default_params(params_filename):
        return _get_config(params_filename)

    def get_dates(self, period_id):
        start_time, end_time = self.df_ab_period[
            self.df_ab_period.period_id == period_id][['start_date', 'end_date']].values[0]
        return [{'calc_date': d.date()} for d in pd.date_range(start_time, end_time)]

    @staticmethod
    def tuplify_metric_params(params_dict):
        if not params_dict:
            return []
        result = []
        for class_name, methods in params_dict.items():
            if class_name not in ['observations_stats', 'compare_observations']:
                continue
            for method, params in methods.items():
                if params is None:
                    params = [dict()]
                rows = [MetricParams(**{**p, 'class_name': class_name, 'method': method}) for p in params]
                result.extend(rows)
        return result

    def get_metric_params(self, ab_test_ext, metric):

        result = []

        ab_metric_params = self.df_ab_metric_params[
            (self.df_ab_metric_params.ab_test_ext == ab_test_ext) &
            (self.df_ab_metric_params.metric == metric)
        ]['params'].values[0]
        if ab_metric_params:
            result.extend(self.tuplify_metric_params(ab_metric_params))

            params_file = ab_metric_params.get('params_file')
            if params_file:
                result.extend(self.tuplify_metric_params(self.get_default_params(params_file)))

            if ab_metric_params.get('override'):
                return result

        metric_params = self.metrics[metric]
        result.extend(self.tuplify_metric_params(metric_params))
        params_file = metric_params.get('params_file')
        if params_file:
            result.extend(self.tuplify_metric_params(self.get_default_params(params_file)))

        if metric_params.get('override'):
            return result

        if not params_file:
            result.extend(self.tuplify_metric_params(self.get_default_params(PARAMS_FILENAME)))

        return list(set(result))

    def get_ab_test(self, ab_test_id):
        ix = self.df_ab_test.ab_test_id == ab_test_id
        return self.df_ab_test[ix].to_dict(orient='records')[0]

    def get_ab_metrics(self, ab_test_id):
        ix = self.df_ab_metric.ab_test_id == ab_test_id
        return self.df_ab_metric[ix][['metric_id', 'metric']].to_dict(orient='records')

    def get_ab_periods(self, ab_test_id):
        ix = self.df_ab_period.ab_test_id == ab_test_id
        return self.df_ab_period[ix][['period_id', 'start_date']].to_dict(orient='records')

    def get_split_groups(self, ab_test_id):
        ix = self.df_ab_split_group.ab_test_id == ab_test_id
        return self.df_ab_split_group[ix][['split_group_id']].to_dict(orient='records')

    def get_split_group_pairs(self, ab_test_id):
        ix = self.df_ab_split_group_pair.ab_test_id == ab_test_id
        cols = ['split_group_id', 'control_split_group_id']
        return self.df_ab_split_group_pair[ix][cols].to_dict(orient='records')

    def get_ab_iters(self, ab_test_id):
        iters = set()

        ab_test = self.get_ab_test(ab_test_id)
        metrics = self.get_ab_metrics(ab_test_id)
        periods = self.get_ab_periods(ab_test_id)
        split_groups = self.get_split_groups(ab_test_id)
        split_group_pairs = self.get_split_group_pairs(ab_test_id)

        for metric, period in itertools.product(metrics, periods):
            dates = self.get_dates(period['period_id'])
            obs_stats_params = [
                prm for prm in self.get_metric_params(ab_test['ab_test_ext'], metric['metric'])
                if prm.class_name == 'observations_stats'
            ]
            comp_obs_params = [
                prm for prm in self.get_metric_params(ab_test['ab_test_ext'], metric['metric'])
                if prm.class_name == 'compare_observations'
            ]
            iters.update({
                Iter(**{
                    'ab_test_id': ab_test['ab_test_id'],
                    'metric_id': metric['metric_id'],
                    'metric': metric['metric'],
                    'period_id': period['period_id'],
                    'start_date': period['start_date'],
                    **d, **os._asdict(), **sg,
                })
                for d, os, sg in itertools.product(dates, obs_stats_params, split_groups)
            })
            iters.update({
                Iter(**{
                    'ab_test_id': ab_test['ab_test_id'],
                    'metric_id': metric['metric_id'],
                    'metric': metric['metric'],
                    'period_id': period['period_id'],
                    'start_date': period['start_date'],
                    **d, **co._asdict(), **sgp,
                })
                for d, co, sgp in itertools.product(dates, comp_obs_params, split_group_pairs)
            })
        return list(iters)

    @cached_property
    def iters_all(self):
        iters = set()
        for ab_test_id in self.df_ab_test.ab_test_id:
            iters.update(self.get_ab_iters(ab_test_id))
        return list(iters)

    @cached_property
    def iters_to_skip(self):
        with connect_vertica() as vcon:
            with vcon.cursor('dict') as cur:
                cur.execute(self._get_sql('sql_iters_to_skip'))
                results = cur.fetchall()
        return list({Iter(**r) for r in results})

    @staticmethod
    def check_iters_equality(iter1, iter2):
        fields = [f for f in iter1._fields
                  if getattr(iter2, f) is not None and
                  getattr(iter1, f) is not None and
                  getattr(iter2, f) != getattr(iter1, f)]
        return len(fields) == 0

    @cached_property
    def iters_to_do(self):
        results = []
        for it in self.iters_all:
            to_add = True
            for iter_to_skip in self.iters_to_skip:
                if self.check_iters_equality(it, iter_to_skip):
                    to_add = False
                    break
            if to_add:
                results.append(it)
        return results


class AbMetrics:
    def __init__(self, ab_iters, n_threads=None):
        self.ab_iters = ab_iters
        self.metrics = _get_config(METRICS_FILENAME)
        if n_threads is None:
            self.n_threads = multiprocessing.cpu_count()
        else:
            self.n_threads = n_threads

    @cached_property
    def observations_iters_to_load(self):
        ObsIter = namedtuple('ObservationIter',
                             ['template', 'period_id', 'start_date', 'calc_date', 'observations'])
        results = set()
        for it in self.ab_iters:
            template = self.metrics[it.metric].get('template', DEFAULT_TEMPLATE)
            r = ObsIter(template, it.period_id, it.start_date, it.calc_date,
                        tuple(self.metrics[it.metric]['observations']))
            results.add(r)
        return list(results)

    @property
    def ab_iters_with_data(self):
        results = []
        for it in self.ab_iters:
            obs = tuple(self.metrics[it.metric]['observations'])
            storage_key = (it.period_id, it.calc_date, obs, it.split_group_id)
            if storage_key in self.observations_storage:
                results.append(it)
        return results

    @staticmethod
    def _load_observation(params):
        template = _get_template(params['template'])
        sql = template.format(**params)
        df = get_df_from_vertica(sql)
        if df.shape[0] == 0:
            return dict()
        obs_cols = [c for c in df.columns if c not in ['split_group_id', 'cnt']]
        return {
            (params['period_id'], params['calc_date'], params['observations'], sg): {
                    'obs': df[df.split_group_id == sg][obs_cols].values,
                    'counts': df[df.split_group_id == sg]['cnt'].values
            }
            for sg in df.split_group_id.unique()
        }

    @cached_property
    def observations_storage(self):
        results = dict()
        with multiprocessing.Pool(self.n_threads) as pool:
            results = [pool.apply_async(self._load_observation, (it._asdict(),))
                       for it in self.observations_iters_to_load]
            results = {k: v for r in results for k, v in r.get().items()}
        return results

    @property
    def obs_stats_storage(self):
        if not hasattr(self, '_obs_stats_storage'):
            self._obs_stats_storage = dict()
        return self._obs_stats_storage

    @property
    def comp_obs_storage(self):
        if not hasattr(self, '_comp_obs_storage'):
            self._comp_obs_storage = dict()
        return self._comp_obs_storage

    def get_obs_stats(self, period_id, calc_date, metric, split_group_id):
        observations = tuple(self.metrics[metric]['observations'])
        storage_key = (period_id, calc_date, observations, split_group_id)
        if storage_key in self.obs_stats_storage:
            return self.obs_stats_storage[storage_key]

        args = self.observations_storage[storage_key]
        obs_stats = ObservationsStats(**args)
        self._obs_stats_storage[storage_key] = obs_stats
        return obs_stats

    def get_comp_obs(self, period_id, calc_date, metric, split_group_id, control_split_group_id):
        observations = tuple(self.metrics[metric]['observations'])
        storage_key = (period_id, calc_date, observations, split_group_id, control_split_group_id)
        if storage_key in self.comp_obs_storage:
            return self.comp_obs_storage[storage_key]

        obs_stats = self.get_obs_stats(period_id, calc_date, metric, split_group_id)
        obs_stats_ctrl = self.get_obs_stats(period_id, calc_date, metric, control_split_group_id)
        comp_obs = CompareObservations(obs_stats, obs_stats_ctrl)
        self._comp_obs_storage[storage_key] = comp_obs
        return comp_obs

    _slow_methods = ('bootstrap_test', 'bootstrap_confint', 'permutation_test', 'permutation_confint')

    def calculate_ab_iter(self, ab_iter):
        if ab_iter.class_name == 'observations_stats':
            obs_stats = self.get_obs_stats(ab_iter.period_id, ab_iter.calc_date,
                                           ab_iter.metric, ab_iter.split_group_id)
            method = getattr(obs_stats, ab_iter.method)
        elif ab_iter.class_name == 'compare_observations':
            comp_obs = self.get_comp_obs(ab_iter.period_id, ab_iter.calc_date, ab_iter.metric,
                                         ab_iter.split_group_id, ab_iter.control_split_group_id)
            method = getattr(comp_obs, ab_iter.method)
        else:
            return
        argnames = [a for a in inspect.getfullargspec(method).args
                    if a in [f for f, v in ab_iter._asdict().items() if v is not None]]
        args = {a: getattr(ab_iter, a) for a in argnames}
        if ab_iter.method in self._slow_methods:
            args['n_threads'] = self.n_threads
        start = default_timer()
        result = method(**args)
        end = default_timer()
        res_dict = {
            **ab_iter._asdict(),
            **result._asdict(),
            'elapsed_seconds': end - start,
        }
        return IterResult(**{k: v for k, v in res_dict.items() if k in IterResult._fields})

    @property
    def fast_ab_iters(self):
        return [i for i in self.ab_iters_with_data if i.method not in self._slow_methods]

    @property
    def slow_ab_iters(self):
        return [i for i in self.ab_iters_with_data if i.method in self._slow_methods]

    @cached_property
    def calc_fast_ab_iters(self):
        return [self.calculate_ab_iter(it) for it in self.fast_ab_iters]

    @cached_property
    def calc_slow_ab_iters(self):
        results = []
        for it in self.slow_ab_iters:
            r = self.calculate_ab_iter(it)
            logger.debug(r)
            results.append(r)
        return results


def validate_config():
    def get_config(config_name):
        with open('../config/{}.yaml'.format(config_name), 'r') as f:
            return yaml.load(f)

    def get_schema(schema_name):
        with open('../config_schemas/{}.yaml'.format(schema_name), 'r') as f:
            return yaml.load(f)

    events_config = get_config('events')
    observations_config = get_config('observations')
    metrics_config = get_config('metrics')

    configs = dict()
    schemas = dict()

    for cn in ['events', 'observations', 'metrics']:
        configs[cn] = get_config(cn)
        schemas[cn] = get_schema(cn)

    schemas['observations']['valueschema']['schema']['events']['allowed'] = list(configs['events'].keys())
    schemas['metrics']['valueschema']['schema']['observations']['allowed'] = list(configs['observations'].keys())

    validator = cerberus.Validator(schemas)
    if not validator.validate(configs):
        raise Exception(validator.errors)
    else:
        print('All good')



