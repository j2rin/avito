import os
import re
from datetime import date, timedelta

import click

from lib.clients.clickhouse import get_connection as ch_get_con
from lib.clients.clickhouse import get_query_columns as ch_get_query_columns
from lib.clients.trino import explain_validate
from lib.clients.trino import get_connection as t_get_con
from lib.clients.vertica import get_connection as v_get_con
from lib.clients.vertica import get_query_columns as v_get_query_columns
from lib.utils import bind_sql_params, get_missing_sql_params, split_statements
from lib.yaml_getters import get_sql_metadata

SQL_DIR = 'sources/sql/'
SQL_FILES_PATTERN = r'{dir}(\w+).sql'.format(dir=SQL_DIR)
PRODUCTION_BRANCH = 'origin/master'
MODIFIED_FILES_PATH = os.getenv('MODIFIED_FILES')
DURATION_SECONDS_LIMIT = 300
REQUIRED_PARAMS = ['first_date', 'last_date']
SQL_PRIMARY_SUBJECT_MAP = {}


def parse_sql_filename(path):
    for n in re.findall(SQL_FILES_PATTERN, path):
        return n


def list_modified_files():
    result = []

    if MODIFIED_FILES_PATH:
        # В TeamCity модифицированные файлы будут подсовываться в файлик
        with open(MODIFIED_FILES_PATH, 'r') as f:
            result = f.read().splitlines()
    else:
        # Для локального запуска
        from git import Repo

        repo = Repo('.')
        origin_master = repo.commit(PRODUCTION_BRANCH)
        for item in origin_master.diff(None):
            result.append(item.a_path)

    return result


def _bind_date_period(sql, n_days):
    last_date = date.today() - timedelta(days=3)
    first_date = last_date - timedelta(days=n_days - 1)
    params = {'first_date': first_date, 'last_date': last_date}
    sql = bind_sql_params(sql, **params)
    return sql


class VerticaFileValidator:
    def __init__(self, sql_metadata, limit0, n_days=1):
        self.limit0 = limit0
        self.n_days = n_days
        self._sql_metadata = sql_metadata

    @staticmethod
    def _execute_limit0(con, sql):
        columns = v_get_query_columns(con, sql)
        return {'output_columns': len(columns)}

    @staticmethod
    def _execute_sql_and_collect_metrics(con, sql, table_name, subject):
        sql_wrapped = f'''
create local temp table {table_name} on commit preserve rows as /*+direct*/ (
select /*+syntactic_join*/ *
from (
{sql}
) _
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

        spilled = report['spilled_gb']
        if spilled <= 300 and report['output_rows'] > 10**6:
            new_report['spilled_exceed'] = ''

        return new_report

    def validate(self, filepath, primary_subject):

        try:

            with open(filepath, 'r') as f:
                sql_raw = f.read()

            missing_params = get_missing_sql_params(sql_raw, REQUIRED_PARAMS)

            if missing_params:
                return {'error': f"Missing required params: `{', '.join(missing_params)}`"}

            sql_bind = _bind_date_period(sql_raw, self.n_days)

            n_statements = len(split_statements(sql_bind))
            if n_statements != 1:
                return {'error': f'Number of statements must be exactly one'}

            with v_get_con() as con:
                report = self._execute_limit0(con, sql_bind)
                if self.limit0:
                    return report

                filename = parse_sql_filename(filepath)

                report |= self._execute_sql_and_collect_metrics(
                    con, sql_bind, filename, primary_subject
                )

                return self._adjust_report(report)

        except Exception as e:
            return {'error': str(e)}


class TrinoFileValidator:
    def __init__(self):
        self.not_found_tables = set()

    def validate(self, filepath):
        try:

            with open(filepath, 'r') as f:
                sql_raw = f.read()

            sql = _bind_date_period(sql_raw, 1)
            with t_get_con() as con:
                result = explain_validate(con, sql)
                if 'error' in result and result['error'].error_name == 'TABLE_NOT_FOUND':
                    match = re.search(r"Table '\w+\.([\w.]+)'", result['error'].message)
                    if match:
                        table_name = match.group(1)
                        self.not_found_tables.add(table_name)
                return result

        except Exception as e:
            return {'error': str(e)}


class ClickhouseFileValidator:
    def validate(self, filepath):

        try:

            with open(filepath, 'r') as f:
                sql_raw = f.read()

            n_statements = len(split_statements(sql_raw))
            if n_statements != 1:
                return {'error': f'Number of statements must be exactly one'}

            sql = _bind_date_period(sql_raw, 1)
            with ch_get_con() as con:
                columns = ch_get_query_columns(con, sql)
                return {'output_columns': len(columns)}

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


REPORT_CONFIG = {
    'duration': 'duration: {value} s',
    'output_rows': 'output_rows: {value}',
    'output_columns': 'output_columns: {value}',
    'input_rows': 'input_rows: {value}',
    'max_memory_gb': 'max_memory: {value} GB',
    'network_received_gb': 'network_received: {value} GB',
    'network_sent_gb': 'network_sent: {value} GB',
    'read_gb': 'read: {value} GB',
    'written_gb': 'written: {value} GB',
    'spilled_gb': 'spilled: {value} GB',
    'cpu_cycles_us': 'cpu_cycles_us: {value}',
    'thread_count': 'thread_count: {value}',
    'session_id': 'session_id: {value}',
    # 'start_time': 'start_time: {value}',
    # 'request': 'request: {value}',
    # 'request_id': 'request_id: {value}',
    # 'tablename': 'tablename: {value}',
    # 'duration_exceed': 'duration_exceed: {value}',
    # 'thread_count_exceed': 'thread_count_exceed: {value}',
    # 'max_memory_exceed': 'max_memory_exceed: {value}',
    # 'network_received_exceed': 'network_received_exceed: {value}',
    # 'network_sent_exceed': 'network_sent_exceed: {value}',
    # 'spilled_exceed': 'spilled_exceed: {value}',
}


def validate(filenames=None, limit0=False, n_days=1, validate_trino=True):
    if filenames:
        modified_files = [f'{SQL_DIR}{fn}.sql' for fn in filenames]
    else:
        modified_files = filter(is_sql_file, list_modified_files())

    success = True
    sql_metadata = get_sql_metadata()
    vertica_validator = VerticaFileValidator(sql_metadata, limit0, n_days)
    clickhouse_validator = ClickhouseFileValidator()
    trino_validator = TrinoFileValidator()

    for path in modified_files:

        report = {}
        filename = parse_sql_filename(path)
        meta = sql_metadata.get(filename)

        if not meta:
            report |= {'error': f'No config in `sources.yaml` found for `{filename}`'}

        elif meta['database'] == 'vertica':
            report |= vertica_validator.validate(path, meta['primary_subject'])
        elif meta['database'] == 'clickhouse':
            report |= clickhouse_validator.validate(path)

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

        if validate_trino:
            trino_validation_result = trino_validator.validate(path)
            if 'error' in trino_validation_result:
                print(
                    f'WARNING: syntax is not valid for Trino. {trino_validation_result["error"]}'
                )

        print('')
        for metric, template in REPORT_CONFIG.items():
            if metric in report:
                print(template.format(value=report[metric]))
        print('')

    if success:
        print('SQL validation PASSED')

    if trino_validator.not_found_tables:
        print(
            f'\nSome tables have not been found in Trino.'
            f"Execute `select public.publish('{','.join(trino_validator.not_found_tables)}');`"
        )
    return success


@click.command()
@click.option('--filename', '-n', 'filenames', type=str, multiple=True)
@click.option('--limit0', '-0', 'limit0', type=str, is_flag=True, default=False)
@click.option('--n-days', '-d', 'n_days', type=int, default=1)
def main(filenames, limit0, n_days):
    validate(filenames, limit0, n_days)


if __name__ == '__main__':
    main()
