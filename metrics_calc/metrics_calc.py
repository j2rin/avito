import itertools
import multiprocessing
import os
from timeit import default_timer
from hashlib import md5
import inspect
from functools import lru_cache
import json

import pandas as pd
from cached_property import cached_property

from ab_significance.significance import ObservationsStats, CompareObservations
from db_utils import connect_postgre, select_df, insert_into_vertica

from utils import *
from log_helper import configure_logger

logger = configure_logger(logger_name='metrics_calc', log_dir=CUR_DIR_PATH)

pd.core.generic.warnings.filterwarnings('ignore')

data_storage = dict()
significance_obj_storage = dict()


def hash_md563(obj):
    h = md5()
    h.update(repr(obj).encode())
    return int(h.hexdigest(), 16) % (2 ** 63 - 1)


def hash_unordered(iterable):
    if len(iterable) == 0:
        return hash_md563([])
    else:
        hashes = [hash_md563(t) for t in iterable]
        return sum(hashes) // len(hashes)


def fill_data_storage(sql_list, index_list=None, data_key_list=None, n_threads=VERTICA_MAX_THREADS, con_method=None,
                      use_cache=False, use_db=True):

    if index_list is None:
        index_list = [None] * len(sql_list)

    if data_key_list is None:
        data_key_list = sql_list

    params_list = set((s, i, d) for s, i, d in zip(sql_list, index_list, data_key_list) if d not in data_storage)

    results = dict()

    if use_cache:
        for p in params_list:
            try:
                results[p[2]] = pd.read_hdf(DATA_CACHE_PATH, p[2])
            except (KeyError, FileNotFoundError):
                pass

    if use_db:
        params_list = set(p for p in params_list if p[2] not in results)

        total_sqls = len(params_list)

        if n_threads > VERTICA_MAX_THREADS:
            n_threads = VERTICA_MAX_THREADS

        logger.info('{0} sqls to load'.format(total_sqls))

        with multiprocessing.Pool(n_threads) as pool:
            res = {k: pool.apply_async(select_df, (s, i, con_method)) for s, i, k in params_list}
            for i, (k, v) in enumerate(res.items()):
                try:
                    data = v.get()
                    logger.info('{0}/{1} loaded'.format(i + 1, total_sqls))
                    if data.shape[0] == 0:
                        continue
                    data.to_hdf(DATA_CACHE_PATH, k)
                    results.update({k: data})
                except Exception as e:
                    logger.error('{0} :: data_key: {1}'.format(e, k))

    data_storage.update(results)


def fill_data_storage_ab(use_cache=False, con=None):
    data_keys = [
        'ab_split_group',
        'iters_to_skip',
        'ab_records',
        'ab_breakdown_dim_filter',
        'metric',
    ]

    sqls = [get_sql(dk) for dk in data_keys]
    indecies = ['ab_test_ext', 'iter_hash', None, 'breakdown_id', 'metric']

    fill_data_storage(sqls, indecies, data_keys, use_cache=use_cache)

    data_keys = []
    pg_sqls = []
    for sname in ['pg_ab_metric_params', 'pg_ab_split_group_pair']:
        data_keys.append(sname)
        pg_sqls.append(get_sql(sname))
    indecies = ['ab_test_ext'] * 2
    fill_data_storage(pg_sqls, indecies, data_keys, con_method=connect_postgre, use_cache=use_cache)


class AbIter:
    def __init__(
        self,

        ab_test_id,
        period_id,
        split_group_id,
        calc_date,

        metric,

        breakdown_id,

        significance_params,
        control_split_group_id=None,
    ):
        self.ab_test_id = ab_test_id
        self.period_id = period_id
        self.split_group_id = split_group_id
        self.control_split_group_id = control_split_group_id
        self.calc_date = calc_date
        self.metric = metric

        self.breakdown_id = breakdown_id

        self.significance_params = {k: v for k, v in significance_params.items() if v is not None}
        self.is_calculated = False

    @property
    def breakdown(self):
        return get_breakdown_values(self.breakdown_id)

    @property
    def breakdown_text(self):
        bkd = ((key, ','.join([str(v) for v in values])) for (key, values) in self.breakdown.items())
        return ';'.join(['{0}[{1}]'.format(dim, values) for dim, values in bkd])

    @cached_property
    def metric_id(self):
        return get_metric_id(self.metric)

    @property
    def observations(self):
        return tuple(get_metrics()[self.metric]['observations'])

    @property
    def numenator(self):
        return get_metrics()[self.metric].get('numenator')

    @property
    def denominator(self):
        return get_metrics()[self.metric].get('denominator')

    @property
    def ab_params(self):
        return {
            'ab_test_id': self.ab_test_id,
            'period_id': self.period_id,
            'split_group_id': self.split_group_id,
            'metric_id': self.metric_id,
            'breakdown_id': self.breakdown_id,
            'calc_date': self.calc_date,
            **({'control_split_group_id': self.control_split_group_id} if self.control_split_group_id else dict()),
        }

    @cached_property
    def metric_template(self):
        return get_metrics()[self.metric].get('template', DEFAULT_TEMPLATE)

    @cached_property
    def sql_template(self):
        return get_template(self.metric_template)

    @staticmethod
    def list_to_sql_str(lst):
        return "'{}'".format("', '".join(lst))

    @cached_property
    def sql_params(self):
        res = {
            'calc_date': self.calc_date,
            'observations': self.observations,
            'observations_str': self.list_to_sql_str(self.observations),
        }
        if self.numenator:
            res.update({
                'numenator_str': self.list_to_sql_str(self.numenator),
                'denominator_str': self.list_to_sql_str(self.denominator),
            })
        return res

    @property
    def sql_breakdown(self):
        bkd = ((key, ', '.join([str(v) for v in values])) for (key, values) in self.breakdown.items())
        return ' '.join(['and {0} in ({1})'.format(dim, values) for dim, values in bkd])

    @cached_property
    def sql(self):
        return self.sql_template.format(**self.sql_params)

    @property
    def data_index_cols(self):
        return ('period_id', 'split_group_id', 'breakdown_id')

    @cached_property
    def data_key(self):
        return str(hash_md563((self.sql, self.data_index_cols)))

    def get_data_index(self, split_group_id):
        d = {
            **self.ab_params,
            'split_group_id': split_group_id,
        }
        return tuple(d[c] for c in self.data_index_cols)

    def fill_data_storage(self, use_cache=True, use_db=True):
        fill_data_storage(sql_list=[self.sql], index_list=[self.data_index_cols], data_key_list=[self.data_key],
                          use_cache=use_cache, use_db=use_db)

    @property
    def data(self):
        return get_data(self.data_key)

    def get_observations(self, split_group_id):
        data_index = self.get_data_index(split_group_id)
        not_value_cols = list(self.data_index_cols) + ['cnt']
        if self.data is not None and data_index in self.data.index:
            df = self.data.loc[data_index]
            obs_columns = [c for c in df.columns if c not in not_value_cols]
            return {
                'obs': df[obs_columns].values,
                'counts': df['cnt'].values,
            }

    @property
    def is_with_data(self):
        return self.get_observations(self.split_group_id) is not None

    def get_obs_stats_obj_key(self, split_group_id):
        sg_tup = ('split_group_id', split_group_id)
        return tuple(
            [
                t for t in self.ab_params.items()
                if t[0] not in ('control_split_group_id', 'split_group_id') and t[1] is not None
            ] + [sg_tup]
        )

    @cached_property
    def significance_obj_key(self):
        return tuple(self.ab_params.items())

    def get_observations_stats_obj(self, split_group_id):
        key = self.get_obs_stats_obj_key(split_group_id)
        if key in significance_obj_storage:
            return significance_obj_storage[key]
        obs_stats = ObservationsStats(**self.get_observations(split_group_id))
        significance_obj_storage[key] = obs_stats
        return obs_stats

    @property
    def significance_obj(self):
        key = self.significance_obj_key
        if key in significance_obj_storage:
            return significance_obj_storage[key]
        if self.significance_params['class_name'] == 'observations_stats':
            return self.get_observations_stats_obj(self.split_group_id)
        elif self.significance_params['class_name'] == 'compare_observations':
            obs_stats_1 = self.get_observations_stats_obj(self.split_group_id)
            obs_stats_2 = self.get_observations_stats_obj(self.control_split_group_id)
            comp_obs = CompareObservations(obs_stats_1, obs_stats_2)
            significance_obj_storage[key] = comp_obs
            return comp_obs

    @cached_property
    def significance_obj_method(self):
        return getattr(self.significance_obj, self.significance_params['method'])

    @property
    def iter_type(self):
        if self.significance_params['method'] in {
            'bootstrap_test',
            'bootstrap_confint',
            'permutation_test',
            'permutation_confint'
        }:
            return 'slow'
        elif self.significance_params['method'] in ('smart_stats', 'smart_stats_pooled') \
                and self.significance_params.get('resampling'):
            return 'slow'
        else:
            return 'fast'

    @cached_property
    def significance_result(self):
        argnames = inspect.getfullargspec(self.significance_obj_method).args
        args = {k: v for k, v in self.significance_params.items() if k in argnames}
        start = default_timer()
        result = self.significance_obj_method(**args)
        end = default_timer()
        self.is_calculated = True
        return {
            **result._asdict(),
            'elapsed_seconds': end - start,
        }

    @property
    def iter_result(self):
        return {
            'iter_hash': self.__hash__(),
            **self.ab_params,
            **self.significance_params,
            **self.significance_result,
        }

    @cached_property
    def iter_hash(self):
        return hash_unordered(list(self.ab_params.items()) + list(self.significance_params.items()))

    def __hash__(self):
        return self.iter_hash

    def __eq__(self, other):
        return self.__hash__() == other.__hash__()


class AbItersStorage:
    def __init__(self, ab_iters=None, skip_existing=True):
        if ab_iters is None:
            ab_iters = get_all_ab_iters()
        ab_iters = list(set(ab_iters))
        if skip_existing:
            data = get_data('iters_to_skip')
            iter_hashes_to_skip = set()
            if data is not None:
                iter_hashes_to_skip = set(data.index)
            ab_iters = [it for it in ab_iters if hash(it) not in iter_hashes_to_skip]

        self.ab_iters = ab_iters

    @property
    def fill_data_storage_args(self):
        zipped = set((it.sql, it.data_index_cols, it.data_key) for it in self.ab_iters)
        return {
            'sql_list': [s[0] for s in zipped],
            'index_list': [s[1] for s in zipped],
            'data_key_list': [s[2] for s in zipped],
        }

    def fill_data_storage(self, use_cache=True, use_db=True):
        fill_data_storage(**self.fill_data_storage_args, use_cache=use_cache, use_db=use_db)

    def ab_iters_filtered(self, iter_type='fast', is_with_data=True):
        return [it for it in self.ab_iters if it.iter_type == iter_type and it.is_with_data == is_with_data]

    def calc_iters_by_type(self, iter_type='fast', save_each=1000):
        records = []
        iters = self.ab_iters_filtered(iter_type=iter_type, is_with_data=True)
        total_iters = len(iters)
        for i, it in enumerate(iters):
            try:
                records.append(it.iter_result)
                logger.info('{0}/{1} iters done :: iter_hash: {2}'.format(i + 1, total_iters, it.iter_hash))
            except Exception as e:
                logger.error('iter_hash: {0} :: {1}'.format(it.iter_hash, e))

            if save_each > 0 and len(records) > 0 and (len(records) % save_each == 0 or i + 1 == total_iters):
                self.save_records_to_vertica(records)
                records = list()

    def save_records_to_vertica(self, records, table_name='saef.ab_result'):
        df = pd.DataFrame.from_records(records)
        insert_into_vertica(df, table_name)
        logger.info('{0} records saved to vertica'.format(len(records)))

    @property
    def iters_results(self):
        return [it.iter_result for it in self.ab_iters if it.is_calculated]


def get_data(data_key):
    if data_key not in data_storage:
        logger.error('No data :: data_key: {}'.format(data_key))
        return
    data = data_storage[data_key]
    return data


def get_ab_something(ix, data_key, fields):
    data = get_data(data_key)
    if data is not None and ix in data.index:
        return data.loc[[ix]][fields].to_dict(orient='records')
    return []


def get_metric_id(metric):
    data = get_data('metric')
    if data is not None and metric in data.index:
        return data.loc[metric]['metric_id']


@lru_cache(maxsize=None)
def get_split_groups(ab_test_ext):
    data_key = 'ab_split_group'
    fields = ['split_group_id']
    return get_ab_something(ab_test_ext, data_key, fields)


def get_split_group_id(ab_test_ext, split_group):
    data = get_data('ab_split_group')
    if data is not None:
        ftr = (data.index == ab_test_ext) & (data.split_group == split_group)
        return data[ftr]['split_group_id'].values[0]


@lru_cache(maxsize=None)
def get_split_group_pairs(ab_test_ext):
    data_key = 'pg_ab_split_group_pair'
    fields = ['split_group', 'control_split_group']
    pairs = get_ab_something(ab_test_ext, data_key, fields)
    return [
        {
            'split_group_id': get_split_group_id(ab_test_ext, p['split_group']),
            'control_split_group_id': get_split_group_id(ab_test_ext, p['control_split_group']),
        } for p in pairs
    ]


@lru_cache(maxsize=None)
def get_metrics():
    return get_config(METRICS_FILENAME)


def get_ab_metric_params(ab_test_ext, metric):
    data = get_data('pg_ab_metric_params').loc[[ab_test_ext]]
    params = data[data.metric == metric]['params'].values[0]
    return params if params else dict()


def flatlify_significance_params(params_dict):
    result = []
    for class_name, methods in params_dict.items():
        if class_name not in ['observations_stats', 'compare_observations']:
            continue
        for method, params in methods.items():
            if params is None:
                params = [dict()]
            rows = [{**p, 'class_name': class_name, 'method': method} for p in params]
            result.extend(rows)
    return result


@lru_cache(maxsize=None)
def get_significance_params(ab_test_ext, metric):

    def get_flat_params(params_filename):
        params = get_params(params_filename)
        return flatlify_significance_params(params)

    metrics = get_config(METRICS_FILENAME)

    ab_metric_params = get_ab_metric_params(ab_test_ext, metric)
    metric_params = metrics[metric]
    default_params = get_flat_params(DEFAULT_PARAMS_FILENAME)

    result = []

    if ab_metric_params:
        result.extend(flatlify_significance_params(ab_metric_params))

        params_filename = ab_metric_params.get('params')
        if params_filename:
            result.extend(get_flat_params(params_filename))

        if ab_metric_params.get('override'):
            return result

    params_flat = flatlify_significance_params(metric_params)
    result.extend(params_flat)

    params_filename = metric_params.get('params')
    if params_filename:
        result.extend(get_flat_params(params_filename))

    if metric_params.get('override'):
        return result

    if not params_filename:
        result.extend(default_params)

    return uniquify_dicts(result)


def get_ab_records():
    return get_data('ab_records').to_dict(orient='records')


@lru_cache(maxsize=None)
def get_all_ab_iters():

    ab_records = get_ab_records()

    iters = list()
    for i, ab_record in enumerate(ab_records):
        ab_test_id = ab_record['ab_test_id']
        ab_test_ext = ab_record['ab_test_ext']
        period_id = ab_record['period_id']
        metric = ab_record['metric']
        breakdown_id = ab_record['breakdown_id']

        ab_split_groups = get_split_groups(ab_test_ext)
        ab_split_group_pairs = get_split_group_pairs(ab_test_ext)

        significance_params = get_significance_params(ab_test_ext, metric)
        obs_stats_params = [prm for prm in significance_params if prm['class_name'] == 'observations_stats']
        comp_obs_params = [prm for prm in significance_params if prm['class_name'] == 'compare_observations']

        os_iters = list(itertools.product(obs_stats_params, ab_split_groups))
        co_oters = list(itertools.product(comp_obs_params, ab_split_group_pairs))

        iters.extend([
            AbIter(
                **{
                    'ab_test_id': ab_test_id,
                    'period_id': period_id,
                    'metric': metric,
                    'breakdown_id': breakdown_id,
                    'calc_date': ab_record['calc_date'],
                    'significance_params': os,
                    **sg,
                }
            )
            for os, sg in os_iters + co_oters
        ])
    return list(set(iters))


def get_ab_iter_by_hash(iter_hash):
    return [it for it in get_all_ab_iters() if hash(it) == iter_hash][0]


@lru_cache(maxsize=None)
def get_breakdown_values(breakdown_id, breakdowns_data=None):
    if breakdowns_data is None:
        breakdowns_data = get_data('ab_breakdown_dim_filter')
    result = dict()
    if breakdown_id in breakdowns_data.index:
        records = breakdowns_data.loc[[breakdown_id]].to_dict(orient='records')
        for r in records:
            s, v = r.values()
            if s in result:
                result[s].append(r['dimension_value'])
            else:
                result[s] = [v]
    return result


def generate_breakdown_text(breakdown):
    bkd = ((key, ', '.join([str(v) for v in values])) for (key, values) in breakdown.items())
    return ';'.join(['{0}[{1}]'.format(dim, values) for dim, values in bkd])


def make_breakdowns_text_df(breakdowns_data):
    result = list()
    for ix in breakdowns_data.index.unique():
        row = get_breakdown_values(ix)
        result.append([ix, json.dumps(row, ensure_ascii=False), generate_breakdown_text(row)])
    return pd.DataFrame.from_records(result, columns=['breakdown_id', 'breakdown_json', 'breakdown_text'])


def insert_breakdown_text_into_vertica(table_name='saef.ab_breakdown_text'):
    data = get_data('ab_breakdown_dim_filter')
    df = make_breakdowns_text_df(data)
    insert_into_vertica(df, table_name, truncate=True)
