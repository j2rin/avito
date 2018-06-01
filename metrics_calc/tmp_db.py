import vertica_python
import multiprocessing
import pandas as pd


def connect_vertica(user='dlenkov', password='Nikolaev24'):
    conn_info = {
        'host': 'vertica-dwh',
        'port': 5433,
        'database': 'DWH',
        'read_timeout': 3600,
    }
    conn_info.update({'user': user, 'password': password})
    return vertica_python.connect(**conn_info)


def select_df(sql, **con_params):

    with connect_vertica(**con_params) as con:
        df = pd.read_sql(sql, con)

    return df


def fill_data_storage(data_sorage, sql_list, n_threads=12):
    if n_threads > 12:
        n_threads = 12

    results = dict()
    with multiprocessing.Pool(n_threads) as pool:
        results = {s: pool.apply_async(select_df, (s,)) for s in sql_list}
        results = {k: v.get() for k, v in results.items()}

    data_storage.update(results)


if __name__ == '__main__':
    data_storage = dict()

    sql_list = ['select {};'.format(i) for i in range(150)]

    fill_data_storage(data_storage, sql_list)

    print(data_storage)
