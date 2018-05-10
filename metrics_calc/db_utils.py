import json
import vertica_python
import pandas as pd
import os
import multiprocessing


DFT_VERTICA_AUTH_FILE = '~/vertica_auth.json'


def connect_vertica(user=None, password=None):
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
    if not user:
        with open(os.path.expanduser(DFT_VERTICA_AUTH_FILE),  'r') as f:
            auth = json.load(f)
        conn_info.update(auth)
    else:
        conn_info.update({'user': user, 'password': password})
    return vertica_python.connect(**conn_info)


def get_df_from_vertica(sql, **conn_params):
    with connect_vertica(**conn_params) as vcon:
        return pd.read_sql(sql, vcon)


import psycopg2
import psycopg2.extras


def connect_postgre():
    """Connects to the specific database."""
    return psycopg2.connect(dbname='ab_config',
                            user='ab_configurator',
                            password='ab_configurator',
                            host='ab-central',
                            port=5432)


class VerticaStorage:

    @property
    def storage(self):
        if not hasattr(self, '_storage'):
            self._storage = dict()
        return self._storage

    def get_data(self, sql):
        if sql not in self.storage:
            self.storage[sql] = get_df_from_vertica(sql)
        return self.storage[sql]

    def load_data_batch(self, sql_list, n_threads=1):
        with multiprocessing.Pool(n_threads) as pool:
            results = dict()
            for sql in sql_list:
                results[sql] = pool.apply_async(get_df_from_vertica, (sql,))
            results = {k: v.get() for k, v in results.items()}
        self.storage.update(results)
