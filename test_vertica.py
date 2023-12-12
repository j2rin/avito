import argparse
import os
import logging
import warnings
from base64 import b64encode
from datetime import date
from pathlib import Path
from http.client import HTTPSConnection
from dotenv import load_dotenv
from vertica_python.errors import Error
from lib.clients import vertica
from lib.utils import bind_sql_params


logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s | %(levelname)-5s | %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S',
)


def read_sql(name):
    file = Path(f'sources/sql/{name}.sql')

    logging.info(f'read {file}')

    if not file.exists():
        raise RuntimeError(f'{file} does not exist')

    return file.read_text()


def basic_auth(username, password):
    token = b64encode(f"{username}:{password}".encode('utf-8')).decode("ascii")
    return f'Basic {token}'


def fetch_master_sql(name):
    logging.info(f'fetch master sql for {name}')

    username = os.getenv('VERTICA_USER', '')
    password = os.getenv('VERTICA_PASSWORD', '')

    conn = HTTPSConnection('stash.msk.avito.ru')
    headers = {'Authorization' : basic_auth(username, password)}

    url = f'/projects/BI/repos/ab-metrics/raw/sources/sql/{name}.sql'

    conn.request('GET', url, headers=headers)

    response = conn.getresponse()
    text = response.read().decode()

    if response.status != 200:
        raise RuntimeError(f'\n{text}')

    return text


def materialize_source(con, sql, event_date, target_table):
    sql = bind_sql_params(sql, first_date=event_date, last_date=event_date)

    cur = con.cursor()

    logging.info(f'drop {target_table}')
    cur.execute(f'drop table if exists {target_table}')

    mat = f'create table if not exists {target_table} as\n{sql}'
    logging.info(f'execute\n{mat}')

    cur.execute(mat)

    logging.info(f'table {target_table} created')


def compare(con, left, right):
    logging.info('check results equality')
    cur = con.cursor()

    cur.execute(f'''
    select throw_error('datasets are not equal')
    from (select * from {left} minus select * from {right}) _
    ''')

    logging.info('datasets are equal')


def main():
    warnings.filterwarnings("ignore")

    parser = argparse.ArgumentParser()
    parser.add_argument('name')
    parser.add_argument('date')

    args = parser.parse_args()

    load_dotenv()

    event_date = date.fromisoformat(args.date)

    logging.info('connect to vertica')
    con = vertica.get_connection()

    master_target = f'public.olap_18596_{args.name}_master'
    branch_target = f'public.olap_18596_{args.name}_branch'

    try:
        branch_sql = read_sql(args.name)
        master_sql = fetch_master_sql(args.name)

        logging.info('materialize master sql')
        materialize_source(con, master_sql, event_date, master_target)

        logging.info('materialize branch sql')
        materialize_source(con, branch_sql, event_date, branch_target)

        logging.info('compare results')
        compare(con, master_target, branch_target)

    except (RuntimeError, Error) as e:
        logging.error(f'{e}')

    finally:
        con.close()


if __name__ == '__main__':
    main()


