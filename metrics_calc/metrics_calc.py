import itertools
import multiprocessing
import os
from timeit import default_timer
from hashlib import md5
import inspect
from functools import lru_cache

import pandas as pd
from cached_property import cached_property

from ab_significance.significance import ObservationsStats, CompareObservations
from db_utils import connect_postgre, select_df

from utils import *
from log_helper import configure_logger

logger = configure_logger(logger_name='metrics_calc', log_dir=CUR_DIR_PATH + 'log/')

VERTICA_MAX_THREADS = 8

data_storage = dict()
significance_obj_storage = dict()


def fill_data_storage(sql_list, index_list=None, data_key_list=None, n_threads=VERTICA_MAX_THREADS, con_method=None):
    if n_threads > VERTICA_MAX_THREADS:
        n_threads = VERTICA_MAX_THREADS

    if index_list is None:
        index_list = [None] * len(sql_list)

    if data_key_list is None:
        data_key_list = sql_list

    params_list = set((s, i, d) for s, i, d in zip(sql_list, index_list, data_key_list) if d not in data_storage)

    with multiprocessing.Pool(n_threads) as pool:
        res = {k: pool.apply_async(select_df, (s, i, con_method)) for s, i, k in params_list}
        results = dict()
        for k, v in res.items():
            try:
                results.update({k: v.get()})
            except Exception as e:
                logger.error('error: {0} :: data_key: {1}'.format(e, k))

    data_storage.update(results)


def fill_data_storage_ab():
    data_keys = [
        'ab_test',
        'ab_metric',
        'ab_period',
        'ab_split_group',
        'ab_period_date',
        'iters_to_skip',
        'metric',
    ]

    sqls = [get_sql(dk) for dk in data_keys]
    indecies = ['ab_test_id'] * (len(data_keys) - 3) + ['period_id', 'iter_hash', 'metric_id']

    fill_data_storage(sqls, indecies, data_keys)

    data_keys = []
    pg_sqls = []
    for sname in ['pg_ab_metric_params', 'pg_ab_split_group_pair']:
        data_keys.append(sname)
        pg_sqls.append(get_sql(sname))
    indecies = ['ab_test_ext'] * 2
    fill_data_storage(pg_sqls, indecies, data_keys, con_method=connect_postgre)


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


class AbIter:
    def __init__(
        self,
        sql_template,

        ab_test_id,
        period_id,
        split_group_id,
        calc_date,

        other_params,

        observations,
        breakdown,

        significance_params,
        control_split_group_id=None,
    ):

        self.sql_template = sql_template

        self.ab_test_id = ab_test_id
        self.period_id = period_id
        self.split_group_id = split_group_id
        self.control_split_group_id = control_split_group_id
        self.calc_date = calc_date

        self.other_params = {k: v for k, v in other_params.items() if v is not None}

        self.observations = observations
        self.breakdown = {k: v for k, v in breakdown.items() if v is not None}

        self.significance_params = {k: v for k, v in significance_params.items() if v is not None}

    @cached_property
    def breakdown_hash(self):
        return hash_unordered([(k, hash_unordered(v)) for k, v in self.breakdown.items()])

    @property
    def breakdown_text(self):
        bkd = ((key, ','.join([str(v) for v in values])) for (key, values) in self.breakdown.items())
        return ';'.join(['{0}[{1}]'.format(dim, values) for dim, values in bkd])

    @property
    def ab_params(self):
        return {
            'ab_test_id': self.ab_test_id,
            'period_id': self.period_id,
            'split_group_id': self.split_group_id,
            'calc_date': self.calc_date,
            'breakdown_hash': self.breakdown_hash,
            **self.other_params,
            **({'control_split_group_id': self.control_split_group_id} if self.control_split_group_id else dict()),
        }

    @property
    def sql_params(self):
        return {
            'calc_date': self.calc_date,
            'observations': self.observations,
            'sql_breakdown': self.sql_breakdown,
            'observations_str': "'{}'".format("', '".join(self.observations)),
        }

    @property
    def sql_breakdown(self):
        bkd = ((key, ', '.join([str(v) for v in values])) for (key, values) in self.breakdown.items())
        return ' '.join(['and {0} in ({1})'.format(dim, values) for dim, values in bkd])

    @property
    def sql(self):
        return self.sql_template.format(**self.sql_params)

    @property
    def data_index_cols(self):
        return ('period_id', 'split_group_id')

    def get_data_index(self, split_group_id):
        d = {
            **self.ab_params,
            'split_group_id': split_group_id,
        }
        return tuple(d[c] for c in self.data_index_cols)

    def fill_data_storage(self):
        fill_data_storage(sql_list=[self.sql], index_list=[self.data_index_cols])

    @cached_property
    def data(self):
        data = get_data(self.sql)
        if data is not None and data.shape[0] == 0:
            logger.error('No data :: iter_hash: {}'.format(self.__hash__()))
            return
        return data

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

    @property
    def significance_obj_method(self):
        return getattr(self.significance_obj, self.significance_params['method'])

    @property
    def iter_type(self):
        return 'slow' if self.significance_params['method'] in {
            'bootstrap_test',
            'bootstrap_confint',
            'permutation_test',
            'permutation_confint'
        } else 'fast'

    @cached_property
    def significance_result(self):
        argnames = inspect.getfullargspec(self.significance_obj_method).args
        args = {k: v for k, v in self.significance_params.items() if k in argnames}
        start = default_timer()
        result = self.significance_obj_method(**args)
        end = default_timer()
        return {
            **result._asdict(),
            'elapsed_seconds': end - start,
        }

    @property
    def calc_iter(self):
        return {
            'iter_hash': self.__hash__(),
            **self.ab_params,
            **self.significance_params,
            **self.significance_result,
            'breakdown': self.breakdown_text,
        }

    def __hash__(self):
        return hash_unordered(list(self.ab_params.items()) + list(self.significance_params.items()))

    def __eq__(self, other):
        return self.__hash__() == other.__hash__()


class AbItersStorage:
    def __init__(self, ab_iters=None):
        if ab_iters is None:
            ab_iters = get_all_ab_iters()
        self.ab_iters = list(set(ab_iters))

    @property
    def iter_hashes_to_skip(self):
        data = get_data('iters_to_skip')
        if data is not None:
            return set(data.index)

    @cached_property
    def ab_iters_to_do(self):
        return [it for it in self.ab_iters if hash(it) not in self.iter_hashes_to_skip]

    @property
    def fill_data_storage_args(self):
        sql_list = [it.sql for it in self.ab_iters_to_do]
        index_list = [it.data_index_cols for it in self.ab_iters_to_do]
        zipped = set(zip(sql_list, index_list))
        return {
            'sql_list': [s[0] for s in zipped],
            'index_list': [s[1] for s in zipped],
        }

    def fill_data_storage(self):
        fill_data_storage(**self.fill_data_storage_args)

    def ab_iters_filtered(self, iter_type='fast', is_with_data=True):
        return [it for it in self.ab_iters_to_do if it.iter_type == iter_type and it.is_with_data == is_with_data]

    def calc_iters_by_type(self, iter_type='fast'):
        return [
            it.calc_iter
            for it in self.ab_iters_filtered(iter_type=iter_type, is_with_data=True)
            if it.iter_type == iter_type and it.is_with_data
        ]


def get_data(data_key):
    if data_key not in data_storage:
        logger.error('You need to fill data_storage first\ndata_key: {}'.format(data_key))
        return
    data = data_storage[data_key]
    return data


def get_ab_something(ix, data_key, fields):
    data = get_data(data_key)
    if data is not None and ix in data.index:
        return data.loc[[ix]][fields].to_dict(orient='records')
    return []


def get_ab_test_ext(ab_test_id):
    data = get_data('ab_test')
    if data is not None and ab_test_id in data.index:
        return data.loc[ab_test_id]['ab_test_ext']


def get_ab_test_id(ab_test_ext):
    data = get_data('ab_test')
    if data is not None:
        ftr = data.ab_test_ext == ab_test_ext
        if data[ftr].shape[0] > 0:
            return data[ftr].index[0]


def get_ab_metrics(ab_test_id):
    data_key = 'ab_metric'
    fields = ['metric_id', 'metric']
    return get_ab_something(ab_test_id, data_key, fields)


def get_metric(metric_id):
    data = get_data('metric')
    if data is not None and metric_id in data.index:
        return data.loc[metric_id]['metric']


def get_ab_periods(ab_test_id):
    data_key = 'ab_period'
    fields = ['period_id', 'start_date', 'end_date']
    return get_ab_something(ab_test_id, data_key, fields)


def get_split_groups(ab_test_id):
    data_key = 'ab_split_group'
    fields = ['split_group_id']
    return get_ab_something(ab_test_id, data_key, fields)


def get_split_group_id(ab_test_ext, split_group):
    data = get_data('ab_split_group')
    if data is not None:
        ab_test_id = get_ab_test_id(ab_test_ext)
        if ab_test_id is not None:
            ftr = (data.index == ab_test_id) & (data.split_group == split_group)
            return data[ftr]['split_group_id'].values[0]


def get_split_group_pairs(ab_test_id):
    data_key = 'pg_ab_split_group_pair'
    ab_test_ext = get_ab_test_ext(ab_test_id)
    fields = ['split_group', 'control_split_group']
    pairs = get_ab_something(ab_test_ext, data_key, fields)
    return [
        {
            'split_group_id': get_split_group_id(ab_test_ext, p['split_group']),
            'control_split_group_id': get_split_group_id(ab_test_ext, p['control_split_group']),
        } for p in pairs
    ]


def get_dates(period_id):
    data_key = 'ab_period_date'
    fields = ['calc_date']
    return get_ab_something(period_id, data_key, fields)


def get_ab_metric_params(ab_test_id, metric_id):
    ab_test_ext = get_ab_test_ext(ab_test_id)
    metric = get_metric(metric_id)
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


def get_significance_params(ab_test_id, metric_id):

    def get_flat_params(params_filename):
        params = get_params(params_filename)
        return flatlify_significance_params(params)

    metrics = get_config(METRICS_FILENAME)
    metric = get_metric(metric_id)

    ab_metric_params = get_ab_metric_params(ab_test_id, metric_id)
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


def get_breakdowns(ab_test_id, metric_id):
    return [dict()]
    ab_metric_params = get_ab_metric_params(ab_test_id, metric_id)
    breakdowns = ab_metric_params.get('breakdowns')
    if not breakdowns:
        return [dict()]
    else:
        breakdowns = [{k: tuple(set(v)) for k, v in b.items()} for b in breakdowns]
        breakdowns = uniquify_dicts(breakdowns)
        return [{k: sorted(v) for k, v in sorted(b.items())} for b in breakdowns]


def get_ab_iters(ab_test_id):

    ab_metrics = get_ab_metrics(ab_test_id)
    ab_periods = get_ab_periods(ab_test_id)
    ab_split_groups = get_split_groups(ab_test_id)
    ab_split_group_pairs = get_split_group_pairs(ab_test_id)
    metrics = get_config(METRICS_FILENAME)

    iters = list()

    for metric, period in itertools.product(ab_metrics, ab_periods):
        metric_id = metric['metric_id']
        period_id = period['period_id']
        template = metrics[metric['metric']].get('template', DEFAULT_TEMPLATE)
        sql_template = get_template(template)
        observations = tuple(metrics[metric['metric']]['observations'])

        dates = get_dates(period_id)
        breakdowns = get_breakdowns(ab_test_id, metric_id)

        significance_params = get_significance_params(ab_test_id, metric_id)
        obs_stats_params = [prm for prm in significance_params if prm['class_name'] == 'observations_stats']
        comp_obs_params = [prm for prm in significance_params if prm['class_name'] == 'compare_observations']

        iters.extend([
            AbIter(
                **{
                    'sql_template': sql_template,
                    'ab_test_id': ab_test_id,
                    'period_id': period_id,
                    'other_params': {**metric, },
                    'observations': observations,
                    'breakdown': b,
                    'significance_params': os,
                    **d, **sg,
                }
            )
            for d, os, sg, b in itertools.product(dates, obs_stats_params, ab_split_groups, breakdowns)
        ])
        iters.extend([
            AbIter(
                **{
                    'sql_template': sql_template,
                    'ab_test_id': ab_test_id,
                    'period_id': period_id,
                    'other_params': {**metric, },
                    'observations': observations,
                    'breakdown': b,
                    'significance_params': co,
                    **d, **sgp,
                }
            )
            for d, co, sgp, b in itertools.product(dates, comp_obs_params, ab_split_group_pairs, breakdowns)
        ])
    return iters


@lru_cache(maxsize=None)
def get_all_ab_iters():
    data = get_data('ab_test')
    if data is not None:
        ab_test_ids = list(data.index)
        ab_iters = list()
        for i in ab_test_ids:
            ab_iters.extend(get_ab_iters(i))
        return list(set(ab_iters))
    return []


def get_ab_iter_by_hash(iter_hash):
    return [it for it in get_all_ab_iters() if hash(it) == iter_hash][0]
