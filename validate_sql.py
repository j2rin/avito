import os
import re
from datetime import date, timedelta

import click
import vertica_python
from yaml_getters import get_sql_primary_subject_map

from utils import bind_sql_params, get_missing_sql_params, split_statements

SQL_DIR = 'sources/sql/'
SQL_FILES_PATTERN = r'{dir}(\w+).sql'.format(dir=SQL_DIR)
PRODUCTION_BRANCH = 'origin/master'
MODIFIED_FILES_PATH = os.getenv('MODIFIED_FILES')
DURATION_SECONDS_LIMIT = 300
REQUIRED_PARAMS = ['first_date', 'last_date']
SQL_PRIMARY_SUBJECT_MAP = {}


def get_vertica_credentials():
    def get_from_env():
        return {
            'host': os.getenv('VERTICA_HOST', 'vertica-dwh'),
            'port': os.getenv('VERTICA_PORT', '5433'),
            'database': os.getenv('VERTICA_DATABASE', 'DWH'),
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


def execute_sql_and_collect_metrics(sql, table_name):
    sql_query_metrics = 'select * from dma.vw_dm_test_limit_exceed;'
    sql_output_rows = f'select count(*) from {table_name}'

    with vertica_python.connect(**get_vertica_credentials()) as con:
        with con.cursor() as cur:
            try:
                cur.execute(sql)
            except Exception as e:
                return {'error': str(e)}
            cur.execute(sql_query_metrics)
            row = cur.fetchone()
            columns = [col.name for col in cur.description]
            result = dict(zip(columns, row))

            cur.execute(sql_output_rows)
            output_rows = cur.fetchone()[0]
            result['output_rows'] = output_rows
            result['output_columns'] = len(columns)

            return result


TEST_SQL_TEMPLATE = '''
create local temp table {file_name} on commit preserve rows as /*+direct*/ (
    {sql}
) order by {primary_subject} segmented by hash({primary_subject}) all nodes
'''


def prepare_test_sql(sql, file_name, primary_subject):
    two_days_ago = date.today() - timedelta(days=3)
    sql = TEST_SQL_TEMPLATE.format(sql=sql, file_name=file_name, primary_subject=primary_subject)
    params = {'first_date': two_days_ago, 'last_date': two_days_ago}
    sql = bind_sql_params(sql, **params)
    return sql


def parse_sql_filename(path):
    for n in re.findall(SQL_FILES_PATTERN, path):
        return n


def adjust_report(report: dict):
    new_report = report.copy()
    output_data_size = report['output_rows'] * report['output_columns']

    network_received = report['network_received_gb']
    # Для очень больших источников лимит network_received пробивается легко
    if network_received <= 100 and output_data_size >= 10**10:
        new_report['network_received_exceed'] = ''

    return new_report


def execute_file_and_collect_metrics(filepath, filename, primary_subject):
    if not primary_subject:
        return {'error': 'No config in `sources.yaml` found for this SQL'}

    with open(filepath, 'r') as f:
        sql_raw = f.read()

    missing_params = get_missing_sql_params(sql_raw, REQUIRED_PARAMS)
    if missing_params:
        return {'error': f"Missing required params: `{', '.join(missing_params)}`"}

    n_statements = len(split_statements(sql_raw))
    if n_statements != 1:
        return {'error': f'Number of statements must be exactly one'}

    sql_prepared = prepare_test_sql(sql_raw, filename, primary_subject)

    print(f'\nExecuting: {filepath}')
    report = execute_sql_and_collect_metrics(sql_prepared, filename)
    if 'error' not in report:
        report = adjust_report(report)
    return report


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
output_rows: {output_rows}
output_columns: {output_columns}
max_memory: {max_memory_gb} GB
network_received: {network_received_gb} GB
network_sent: {network_sent_gb} GB
read: {read_gb} GB
written: {written_gb} GB
spilled: {spilled_gb} GB
cpu_cycles_us: {cpu_cycles_us}
thread_count: {thread_count}
session_id: {session_id}
'''


def validate(filenames=None):
    if filenames:
        modified_files = [f'{SQL_DIR}{fn}.sql' for fn in filenames]
    else:
        modified_files = filter(is_sql_file, list_modified_files())
    sql_primary_subject_map = get_sql_primary_subject_map()

    success = True
    for path in modified_files:
        filename = parse_sql_filename(path)
        primary_subject = sql_primary_subject_map.get(filename)

        report = execute_file_and_collect_metrics(path, filename, primary_subject)

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


@click.command()
@click.option('--filename', '-fn', 'filenames', type=str, multiple=True)
def main(filenames):
    validate(filenames)


if __name__ == '__main__':
    main()
