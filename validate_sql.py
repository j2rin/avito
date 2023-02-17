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


def parse_sql_filename(path):
    for n in re.findall(SQL_FILES_PATTERN, path):
        return n


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


def bind_date_period(sql):
    two_days_ago = date.today() - timedelta(days=3)
    params = {'first_date': two_days_ago, 'last_date': two_days_ago}
    sql = bind_sql_params(sql, **params)
    return sql


class SQLFileValidator:
    def __init__(self, limit0, n_days=1):
        self.limit0 = limit0
        self.n_days = n_days
        self._sql_primary_subject_map = get_sql_primary_subject_map()

    @staticmethod
    def _bind_date_period(sql, n_days):
        last_date = date.today() - timedelta(days=3)
        first_date = last_date - timedelta(days=n_days - 1)
        params = {'first_date': first_date, 'last_date': last_date}
        sql = bind_sql_params(sql, **params)
        return sql

    @staticmethod
    def _execute_limit0(con, sql):
        sql_limit0 = f'select * from ({sql}) _\nlimit 0'
        with con.cursor() as cur:
            cur.execute(sql_limit0)
            return {'output_columns': len(cur.description)}

    @staticmethod
    def _execute_sql_and_collect_metrics(con, sql, table_name, subject):
        sql_wrapped = f'''
create local temp table {table_name} on commit preserve rows as /*+direct*/ (
select /*+syntactic_join*/ *
from (
{sql}
) _
where {subject} is not null
) order by {subject} segmented by hash({subject}) all nodes
'''

        with con.cursor() as cur:
            cur.execute(sql_wrapped)

            cur.execute(
                'select * from dma.vw_dm_test_limit_exceed order by start_time desc limit 1;'
            )
            row = cur.fetchone()
            columns = [col.name for col in cur.description]
            result = dict(zip(columns, row))

            cur.execute(f'select count(*) from {table_name}')
            output_rows = cur.fetchone()[0]
            result['output_rows'] = output_rows

            return result

    @staticmethod
    def _adjust_report(report: dict):
        new_report = report.copy()
        output_data_size = report['output_rows'] * report['output_columns']

        network_received = report['network_received_gb']
        # Для очень больших источников лимит network_received пробивается легко
        if network_received <= 100 and output_data_size >= 10**10:
            new_report['network_received_exceed'] = ''
        new_report['thread_count_exceed'] = ''

        return new_report

    def validate(self, filepath):

        try:

            with open(filepath, 'r') as f:
                sql_raw = f.read()

            missing_params = get_missing_sql_params(sql_raw, REQUIRED_PARAMS)

            if missing_params:
                return {'error': f"Missing required params: `{', '.join(missing_params)}`"}

            sql_bind = self._bind_date_period(sql_raw, self.n_days)

            n_statements = len(split_statements(sql_bind))
            if n_statements != 1:
                return {'error': f'Number of statements must be exactly one'}

            with vertica_python.connect(**get_vertica_credentials()) as con:
                report = self._execute_limit0(con, sql_bind)
                if self.limit0:
                    return report

                filename = parse_sql_filename(filepath)
                primary_subject = self._sql_primary_subject_map.get(filename)

                if not primary_subject:
                    return {'error': f'No config in `sources.yaml` found for `{filename}`'}

                report |= self._execute_sql_and_collect_metrics(
                    con, sql_bind, filename, primary_subject
                )

                return self._adjust_report(report)

        except Exception as e:
            return {'error': str(e)}


def is_sql_file(filepath):
    return re.match(SQL_FILES_PATTERN, filepath) is not None


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


def validate(filenames=None, limit0=False, n_days=1):
    if filenames:
        modified_files = [f'{SQL_DIR}{fn}.sql' for fn in filenames]
    else:
        modified_files = filter(is_sql_file, list_modified_files())

    success = True
    for path in modified_files:

        report = SQLFileValidator(limit0, n_days).validate(path)

        if 'error' in report:
            print(f'FAILED: {path}')
            print(report['error'])
            success = False
            continue

        exceed = get_exceed_metrics(report)
        if not exceed:
            print(f'PASSED: {path}')

        else:
            print(f'FAILED: {path}')
            for metric, value in exceed.items():
                print(f'{metric}: {value}')
                success = False

        if not limit0:
            print(METRICS_REPORT_TEMPLATE.format(**report))

    if success:
        print('SQL validation PASSED')

    return success


@click.command()
@click.option('--filename', '-n', 'filenames', type=str, multiple=True)
@click.option('--limit0', '-0', 'limit0', type=str, is_flag=True, default=False)
@click.option('--n-days', '-d', 'n_days', type=int, default=1)
def main(filenames, limit0, n_days):
    validate(filenames, limit0, n_days)


if __name__ == '__main__':
    main()
