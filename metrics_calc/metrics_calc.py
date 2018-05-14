from collections import namedtuple
import itertools
import datetime
import multiprocessing
import inspect
import json
import os
from timeit import default_timer

import pandas as pd
from cached_property import cached_property
import yaml
import cerberus

from log_helper import configure_logger
from ab_significance.significance import ObservationsStats, CompareObservations
from db_utils import connect_postgre, connect_vertica, get_df_from_vertica
from storage import ObservationsStorage

from settings import *


FILTER_FIELDS = [
    'ab_test_id',
    'start_date',
    'calc_date',
    'period_id',
]

DIMENSION_FIELDS = []

SPLIT_GROUPS_FIELDS = [
    'split_group_id',
    'control_split_group_id',
]

METRIC_FIELDS = [
    'metric_id',
    'metric',
]

METRIC_PARAMS_FIELDS = [
    'class_name',
    'method',
    'stat_func',
    'comp_func',
    'null_value',
    'alternative',
    'alpha',
    'is_pivotal',
    'n_iters',
]

RESULT_FIELDS = [
    'mean',
    'std',
    'n_obs',
    'p_value',
    'test_statistic',
    'lower_bound',
    'upper_bound',
    'elapsed_seconds'
]

ITER_FIELDS = ['iter_hash'] + FILTER_FIELDS + DIMENSION_FIELDS + SPLIT_GROUPS_FIELDS + \
              METRIC_FIELDS + METRIC_PARAMS_FIELDS
ITER_RESULT_FIELDS = ITER_FIELDS + RESULT_FIELDS

Iter = namedtuple('Iter', ITER_FIELDS)
Iter.__new__.__defaults__ = (None,) * len(Iter._fields)
MetricParams = namedtuple('MetricParams', METRIC_PARAMS_FIELDS)
MetricParams.__new__.__defaults__ = (None,) * len(MetricParams._fields)
IterResult = namedtuple('IterResult', ITER_RESULT_FIELDS)
IterResult.__new__.__defaults__ = (None,) * len(IterResult._fields)
ObsIter = namedtuple('ObservationIter', FILTER_FIELDS + ['sql', 'observations'])


def _get_yaml(config_path, filename):
    if USE_LOCAL:
        url = config_path + filename + '.yaml'
        with open(url, 'r') as f:
            return yaml.load(f)
    else:
        url = 'http://stash.msk.avito.ru/projects/BI/repos/ab-metrics/raw/config/' + filename + '.yaml'
        with requests.get(url) as r:
            return yaml.load(r.text)


def _get_config(filename):
    return _get_yaml(CONFIG_PATH, filename)


def _get_params(filename):
    return _get_yaml(PARAMS_PATH, filename)


def _get_template(filename):
    if USE_LOCAL:
        url = TEMPLATES_PATH + filename + '.sql'
        with open(url, 'r') as f:
            return f.read()
    else:
        url = 'http://stash.msk.avito.ru/projects/BI/repos/ab-metrics/raw/templates/' + filename + '.sql'
        with requests.get(url) as r:
            return f.read()


logger = configure_logger(logger_name='metrics_calc', log_dir=CUR_DIR_PATH + '/log')


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

        logger.info('AbMetricsIters initialized')

    @staticmethod
    def _get_sql(script_name):
        url = CUR_DIR_PATH + '/scripts.sql'
        with open(url, 'r') as f:
            return yaml.load(f)[script_name]

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

            params_filename = ab_metric_params.get('params')
            if params_filename:
                result.extend(self.tuplify_metric_params(_get_params(params_filename)))

            if ab_metric_params.get('override'):
                return result

        metric_params = self.metrics[metric]
        result.extend(self.tuplify_metric_params(metric_params))
        params_filename = metric_params.get('params')
        if params_filename:
            result.extend(self.tuplify_metric_params(_get_params(params_filename)))

        if metric_params.get('override'):
            return result

        if not params_filename:
            result.extend(self.tuplify_metric_params(_get_params(DEFAULT_PARAMS_FILENAME)))

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

        return [Iter(**{
            **it._asdict(),
            'iter_hash': hash(tuple((k, v) for k, v in it._asdict().items() if v is not None))
        }) for it in iters]

    @cached_property
    def iters_to_skip(self):
        with connect_vertica() as vcon:
            with vcon.cursor('dict') as cur:
                cur.execute(self._get_sql('sql_iters_to_skip'))
                results = cur.fetchall()
        return {r['iter_hash'] for r in results}

    @cached_property
    def iters_to_do(self):
        return [it for it in self.iters_all if it.iter_hash not in self.iters_to_skip]


class AbMetrics:
    def __init__(self, ab_iters, n_threads=None):
        self.ab_iters = ab_iters
        self.metrics = _get_config(METRICS_FILENAME)
        if n_threads is None:
            self.n_threads = multiprocessing.cpu_count()
        else:
            self.n_threads = n_threads

        logger.info('AbMetrics initialized')

    @cached_property
    def observations_iters_to_load(self):
        return list(set([self.obs_iter_from_ab_iter(it) for it in self.ab_iters]))

    @cached_property
    def observations_storage(self):
        observations_storage = ObservationsStorage()
        observations_iters_to_load_list = [it._asdict() for it in self.observations_iters_to_load]
        observations_storage.load_data_batch(observations_iters_to_load_list, n_threads=self.n_threads)
        return observations_storage

    def obs_iter_from_ab_iter(self, ab_iter):
        template = self.metrics[ab_iter.metric].get('template', DEFAULT_TEMPLATE)
        sql_template = _get_template(template)
        observations = tuple(self.metrics[ab_iter.metric]['observations'])
        obs_iter_kwargs = {
            'sql': sql_template,
            'observations': observations
        }
        obs_iter_kwargs.update({f: ab_iter.__getattribute__(f) for f in FILTER_FIELDS})
        return ObsIter(**obs_iter_kwargs)

    def get_observations_data(self, obs_iter):
        return self.observations_storage.get_data(**obs_iter._asdict())

    def get_observation(self, obs_iter, split_group_id):
        return self.observations_storage.get_observation(**{
            **obs_iter._asdict(),
            'split_group_id': split_group_id,
        })

    @cached_property
    def ab_iters_with_data(self):
        return [
            it for it in self.ab_iters if self.get_observations_data(self.obs_iter_from_ab_iter(it)).shape[0] > 0
        ]

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

    def get_obs_stats(self, obs_iter, split_group_id):
        storage_key = (obs_iter, split_group_id)
        if storage_key in self.obs_stats_storage:
            return self.obs_stats_storage[storage_key]
        args = self.get_observation(obs_iter, split_group_id)
        obs_stats = ObservationsStats(**args)
        self._obs_stats_storage[storage_key] = obs_stats
        return obs_stats

    def get_comp_obs(self, obs_iter, split_group_id, control_split_group_id):
        storage_key = (obs_iter, split_group_id, control_split_group_id)
        if storage_key in self.comp_obs_storage:
            return self.comp_obs_storage[storage_key]
        obs_stats = self.get_obs_stats(obs_iter, split_group_id)
        obs_stats_ctrl = self.get_obs_stats(obs_iter, control_split_group_id)
        comp_obs = CompareObservations(obs_stats, obs_stats_ctrl)
        self._comp_obs_storage[storage_key] = comp_obs
        return comp_obs

    _slow_methods = ('bootstrap_test', 'bootstrap_confint', 'permutation_test', 'permutation_confint')

    def calculate_ab_iter(self, ab_iter):
        obs_iter = self.obs_iter_from_ab_iter(ab_iter)
        if ab_iter.class_name == 'observations_stats':
            obs_stats = self.get_obs_stats(obs_iter, ab_iter.split_group_id)
            method = getattr(obs_stats, ab_iter.method)
        elif ab_iter.class_name == 'compare_observations':
            comp_obs = self.get_comp_obs(obs_iter, ab_iter.split_group_id, ab_iter.control_split_group_id)
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

    @cached_property
    def fast_ab_iters(self):
        return [i for i in self.ab_iters_with_data if i.method not in self._slow_methods]

    @cached_property
    def slow_ab_iters(self):
        return [i for i in self.ab_iters_with_data if i.method in self._slow_methods]

    @cached_property
    def calc_fast_ab_iters(self):
        results = [self.calculate_ab_iter(it) for it in self.fast_ab_iters]
        logger.info('calc_fast_ab_iters completed')
        return results

    @cached_property
    def calc_slow_ab_iters(self):
        results = []
        logger.info('calc_slow_ab_iters started')
        for it in self.slow_ab_iters:
            r = self.calculate_ab_iter(it)
            results.append(r)
        return results
