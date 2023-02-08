import os
import re
from datetime import date, timedelta

import vertica_python
from dotenv import load_dotenv

SQL_FILES_PATTERN = r'sources/sql/([a-zA-Z0-9_]*).sql'
PRODUCTION_BRANCH = 'origin/master'

load_dotenv()
VERTICA_CONFIG = {
    'host': os.getenv('VERTICA_HOST', 'vertica-dwh'),
    'port': os.getenv('VERTICA_PORT', '5433'),
    'user': os.getenv('VERTICA_USER', ''),
    'password': os.getenv('VERTICA_PASSWORD', ''),
}
DURATION_LIMIT = 300


def list_modified_files():
    result = []
    try:
        # Для локального запуска
        from git import Repo

        repo = Repo('.')
        origin_master = repo.commit(PRODUCTION_BRANCH)

        for item in origin_master.diff(None):
            result.append(item.a_path)
    except ImportError:
        # В TeamCity модифицированные файлы будут подсовываться в файлик
        with open('modified_files.txt', 'r') as f:
            print(f.read())
    except Exception:
        raise

    return result


def is_sql_file(filepath):
    return re.match(SQL_FILES_PATTERN, filepath) is not None


def bind_sql_params(sql, **params):
    for name, value in params.items():
        if isinstance(value, (str, date)):
            value = f"'{value}'"
        pattern = r'(\:{name})\b'.format(name=name)
        sql = re.sub(pattern, value, sql)
    return sql


def execute_sql_and_collect_metrics(sql):
    sql_query_metrics = 'select * from dma.vw_dm_test_limit_exceed;'

    with vertica_python.connect(**VERTICA_CONFIG) as con:
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
    sql_prepared = prepare_test_sql(sql_raw)
    return execute_sql_and_collect_metrics(sql_prepared)


def parse_sql_filename(path):
    for n in re.findall(SQL_FILES_PATTERN, path):
        return n


def get_exceed_metrics(execution_result):
    result = {}
    for field, value in execution_result.items():
        if field.endswith('_exceed') and value:
            result[field] = value
        elif field == 'duration_exceed':
            fact_dur = execution_result['duration']
            if fact_dur > DURATION_LIMIT:
                result[field] = f'{fact_dur}>{DURATION_LIMIT}'
    return result


def validate():
    print('Validating SQL...')
    modified_files = filter(is_sql_file, list_modified_files())
    success = True
    for path in modified_files:
        report = execute_file_and_collect_metrics(path)

        if 'error' in report:
            print(f'FAILED: {path}')
            print(report['error'])
            success = False
            continue

        exceed = get_exceed_metrics(report)
        if not exceed:
            print(f'PASSED: {path}')
            continue

        print(f'FAILED: {path}')
        for metric, value in exceed.items():
            print(f'{metric}: {value}')
            success = False

    if success:
        print('\nSQL validation PASSED')

    return success


if __name__ == '__main__':
    validate()
