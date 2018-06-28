import json
import vertica_python
import pandas as pd
import os
import multiprocessing
import psycopg2
import psycopg2.extras
import datetime


def connect_postgre(user=None, password=None):
    """Connects to the specific database."""
    return psycopg2.connect(dbname='ab_config',
                            user='ab_configurator',
                            password='ab_configurator',
                            host='ab-central',
                            port=5432)


DFT_VERTICA_AUTH_FILE = '~/workspace/wallet/vertica_auth.json'
VERTICA_MAX_THREADS = 12


def connect_vertica(user=None, password=None):
    conn_info = {
        'host': 'vertica-dwh',
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


def select_df(sql, index=None, con_method=None, **con_params):
    if con_method is None:
        con_method = connect_vertica
    if isinstance(index, tuple):
        index = list(index)
    with con_method(**con_params) as con:
        df = pd.read_sql(sql, con, index_col=index)

    return df


def insert_into_vertica(df, tablename):
    df['insert_datetime'] = datetime.datetime.now()
    csv = df.to_csv(
        sep='^',
        index=False,
        header=False,
        float_format='%.16g'
    )
    columns_sql = ', '.join(df.columns)
    query = \
        "COPY {t} ({c}) from stdin DELIMITER '^' ABORT ON ERROR DIRECT;".format(t=tablename, c=columns_sql)
    with connect_vertica() as con:
        with con.cursor() as cur:
            cur.copy(query, csv)
