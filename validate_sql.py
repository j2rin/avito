import os
import re
from datetime import date, timedelta

import vertica_python

from utils import bind_sql_params, get_missing_sql_params, split_statements

SQL_FILES_PATTERN = r'sources/sql/(\w+).sql'
PRODUCTION_BRANCH = 'origin/master'
MODIFIED_FILES_PATH = os.getenv('MODIFIED_FILES')
DURATION_SECONDS_LIMIT = 300
REQUIRED_PARAMS = ['first_date', 'last_date']


def get_vertica_credentials():
    def get_from_env():
        return {
            'host': os.getenv('VERTICA_HOST', 'vertica-dwh'),
            'port': os.getenv('VERTICA_PORT', '5433'),
            'user': os.getenv('VERTICA_USER', ''),
            'password': os.getenv('VERTICA_PASSWORD', ''),
        }

    from_env = get_from_env()
    if not from_env['user']:
        # Если не нашлись креды, пробуем загрузить из файла `.env`
        # Для удобства локального запуска
        from dotenv import load_dotenv

        load_dotenv()
        return get_from_env()
    return from_env


def list_modified_files():
    try:
        # Для локального запуска
        from git import Repo

        repo = Repo('.')
        origin_master = repo.commit(PRODUCTION_BRANCH)
        result = []
        for item in origin_master.diff(None):
            result.append(item.a_path)
    except ImportError:
        # В TeamCity модифицированные файлы будут подсовываться в файлик
        with open(MODIFIED_FILES_PATH, 'r') as f:
            result = f.read().splitlines()
    except Exception:
        raise

    return result


def is_sql_file(filepath):
    return re.match(SQL_FILES_PATTERN, filepath) is not None


def execute_sql_and_collect_metrics(sql):
    sql_query_metrics = 'select * from dma.vw_dm_test_limit_exceed;'

    with vertica_python.connect(**get_vertica_credentials()) as con:
        with con.cursor() as cur:
            try:
                cur.execute(sql)
            except Exception as e:
                return {'error': str(e)}
            cur.execute(sql_query_metrics)
            row = cur.fetchone()
            columns = [col.name for col in cur.description]
            return dict(zip(columns, row))


def prepare_test_sql(sql):
    two_days_ago = date.today() - timedelta(days=2)
    sql = f'select count(*) from ({sql}) _'
    params = {'first_date': two_days_ago, 'last_date': two_days_ago}
    sql = bind_sql_params(sql, **params)
    return sql


def execute_file_and_collect_metrics(filepath):
    with open(filepath, 'r') as f:
        sql_raw = f.read()

    missing_params = get_missing_sql_params(sql_raw, REQUIRED_PARAMS)
    if missing_params:
        return {'error': f"Missing required params: `{', '.join(missing_params)}`"}

    n_statements = len(split_statements(sql_raw))
    if n_statements != 1:
        return {'error': f'Number of statements must be exactly one'}

    sql_prepared = prepare_test_sql(sql_raw)
    return execute_sql_and_collect_metrics(sql_prepared)


def get_exceed_metrics(execution_result):
    result = {}
    for field, value in execution_result.items():
        if field.endswith('_exceed') and value:
            result[field] = value
        elif field == 'duration_exceed':
            fact_dur = execution_result['duration']
            if fact_dur > DURATION_SECONDS_LIMIT:
                result[field] = f'{fact_dur}>{DURATION_SECONDS_LIMIT}'
    return result


METRICS_REPORT_TEMPLATE = '''
duration: {duration} s
input_rows: {input_rows}
max_memory: {max_memory_gb} GB
network_received: {network_received_gb} GB
network_sent: {network_sent_gb} GB
read: {read_gb} GB
written: {written_gb} GB
spilled: {spilled_gb} GB
cpu_cycles_us: {cpu_cycles_us} GB
thread_count: {thread_count}
session_id: {session_id}
'''


def validate():
    modified_files = filter(is_sql_file, list_modified_files())
    success = True
    for path in modified_files:
        report = execute_file_and_collect_metrics(path)

        if 'error' in report:
            print(f'\nFAILED: {path}')
            print(report['error'])
            success = False
            continue

        exceed = get_exceed_metrics(report)
        if not exceed:
            print(f'\nPASSED: {path}')

        else:
            print(f'\nFAILED: {path}')
            for metric, value in exceed.items():
                print(f'{metric}: {value}')
                success = False

        print(METRICS_REPORT_TEMPLATE.format(**report))

    if success:
        print('SQL validation PASSED')

    return success


if __name__ == '__main__':
    validate()
