import os
import re
from datetime import date, timedelta
from pathlib import Path

import click

from lib.clients.clickhouse import get_connection as ch_get_con
from lib.clients.clickhouse import get_query_columns as ch_get_query_columns
from lib.clients.trino import explain_analyze, explain_validate
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

METRIC_LIMITS = {
    'cpu': 17000000000,
    'duration': 3600,
    'duration_ch': 600,
    'duration_min': 60,
    'input_rows': 1000000000000,
    'max_memory_gb': 20,
    'network_gb_received': 50,
    'network_gb_sent': 90,
    'output_rows': 1000000000000,
    'read_gb': 200,
    'spilled_gb': 100,
    'thread_count': 30000,
    'written_gb': 100,
}


class Report:
    def __init__(self, path):
        self._metrics = []
        self._errors = []
        self._warnings = []
        self._path = path

    def add_error(self, kind, message):
        self._errors.append(dict(kind=kind, message=message))

    def add_warning(self, kind, message):
        self._warnings.append(dict(kind=kind, message=message))

    def add_metrics(self, kind, metrics):
        for m, v in metrics.items():
            limit = METRIC_LIMITS.get(m)
            ok = True
            if limit:
                ok = v <= limit
            self._metrics.append(dict(kind=kind, metric=m, value=v, ok=ok))

    def print_errors(self):
        if self._errors:
            print(f'ERROR: {self._path}')
            for error in self._errors:
                print('{kind}: {message}'.format(**error))
            print('')
            return True
        return False

    def get_metric(self, kind, metric):
        for m in self._metrics:
            if m['metric'] == metric and m['kind'] == kind:
                return m

    def get_exceed_metrics(self):
        return [m for m in self._metrics if not m['ok']]

    @staticmethod
    def print_metric(m):
        value = m['value']
        limit = METRIC_LIMITS.get(m['metric'], '')
        if limit:
            limit = f' (limit {limit})'
        print(f"[{m['kind']}] {m['metric']}: {value}{limit}")

    def print_exceed(self):
        exceed_metrics = self.get_exceed_metrics()
        if exceed_metrics:
            print(f'ERROR: {self._path}')
            for m in exceed_metrics:
                self.print_metric(m)
            print('')
            return True
        return False

    def print_metrics(self):
        if self._metrics:
            print(f'INFO: {self._path}')
            for metric in self._metrics:
                self.print_metric(metric)
            print('')

    def print_warnings(self):
        if self._warnings:
            print(f'WARNING: {self._path}')
            for warning in self._warnings:
                print(f"[{warning['kind']}] {warning['message']}")
            print('')


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


def uncomment_keyword_lines(sql, keyword):
    # Create a pattern to uncomment line comments where the specified keyword is at the end
    pattern = r'^\s*--\s*(.*?)\s*{}\s*$'.format(re.escape(keyword))
    return re.sub(pattern, r'\1', sql, flags=re.MULTILINE).strip()


class SyntaxFileValidator:
    def validate(self, filepath, report: Report):

        sql_raw = Path(filepath).read_text()

        missing_params = get_missing_sql_params(sql_raw, REQUIRED_PARAMS)

        if missing_params:
            report.add_error('syntax', f"Missing required params: `{', '.join(missing_params)}`")

        n_statements = len(split_statements(sql_raw))
        if n_statements != 1:
            report.add_error('syntax', f'Number of statements must be exactly one')


class VerticaFileValidator:
    def __init__(self, limit0, n_days=1):
        self.limit0 = limit0
        self.n_days = n_days

    @staticmethod
    def _execute_limit0(con, sql):
        columns = v_get_query_columns(con, sql)
        return {'output_columns': len(columns)}

    @staticmethod
    def _execute_sql_and_collect_metrics(con, sql, table_name, subject):
        sql = uncomment_keyword_lines(sql, '@vertica')

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
                '''
                select
                        duration,
                        input_rows,
                        max_memory_gb,
                        network_received_gb,
                        network_sent_gb,
                        read_gb,
                        written_gb,
                        spilled_gb,
                        cpu_cycles_us,
                        thread_count,
                        session_id
                 from dma.vw_dm_test_limit_exceed
                 order by start_time desc limit 1;'''
            )
            row = cur.fetchone()
            columns = [col.name for col in cur.description]
            result = dict(zip(columns, row))

            cur.execute(f'select count(*) from {table_name}')
            output_rows = cur.fetchone()[0]
            result['output_rows'] = output_rows

            return result

    @staticmethod
    def _adjust_metrics(report: dict):
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

    def validate(self, filepath, primary_subject, report: Report):

        try:
            sql_raw = Path(filepath).read_text()
            sql_bind = _bind_date_period(sql_raw, self.n_days)
            with v_get_con() as con:

                report.add_metrics('vertica', self._execute_limit0(con, sql_bind))
                if self.limit0:
                    return

                filename = parse_sql_filename(filepath)

                metrics = self._execute_sql_and_collect_metrics(
                    con, sql_bind, filename, primary_subject
                )

                # adjusted = self._adjust_metrics(metrics)

                report.add_metrics('vertica', metrics)

        except Exception as e:
            return report.add_error('vertica', str(e))


class TrinoFileValidator:
    def __init__(self, limit0=True, n_days=1):
        self.not_found_tables = set()
        self.limit0 = limit0
        self.n_days = n_days

    def validate(self, filepath, report):
        try:

            sql_raw = Path(filepath).read_text()

            sql = _bind_date_period(sql_raw, 1)
            sql = uncomment_keyword_lines(sql, '@trino')

            with t_get_con() as con:
                result = explain_validate(con, sql)
                if 'error' in result:
                    message = result['error'].message
                    if result['error'].error_name == 'TABLE_NOT_FOUND':
                        match = re.search(r"Table '\w+\.([\w.]+)'", message)
                        if match:
                            table_name = match.group(1)
                            self.not_found_tables.add(table_name)
                    report.add_warning('trino', message)

                    return

                if self.limit0:
                    return

                result = explain_analyze(con, sql)
                if 'error' in result:
                    report.add_warning('trino', result['error'].message)
                    return
                report.add_metrics('trino', result)

        except Exception as e:
            return report.add_error('trino', str(e))


class ClickhouseFileValidator:
    def validate(self, filepath, report: Report):

        try:

            with open(filepath, 'r') as f:
                sql_raw = f.read()

            sql = _bind_date_period(sql_raw, 1)
            with ch_get_con() as con:
                columns = ch_get_query_columns(con, sql)
                report.add_metrics('clickhouse', {'output_columns': len(columns)})

        except Exception as e:
            report.add_error('clickhouse', str(e))


def is_sql_file(filepath):
    return re.match(SQL_FILES_PATTERN, filepath) is not None


def validate(filenames=None, limit0=False, n_days=1, validate_all=False, vertica_trino_flags=1):
    if filenames:
        modified_files = [f'{SQL_DIR}{fn}.sql' for fn in filenames]
    elif validate_all:
        modified_files = [f'{SQL_DIR}{fn}' for fn in os.listdir(SQL_DIR)]
    else:
        modified_files = filter(is_sql_file, list_modified_files())

    success = True
    sql_metadata = get_sql_metadata()

    syntax_validator = SyntaxFileValidator()
    vertica_validator = VerticaFileValidator(limit0, n_days)
    clickhouse_validator = ClickhouseFileValidator()
    trino_validator = TrinoFileValidator(limit0, n_days)

    for path in modified_files:

        report = Report(path)
        filename = parse_sql_filename(path)
        meta = sql_metadata.get(filename)

        if not meta:
            report.add_error('repo', f'No config in `sources.yaml` found for `{filename}`')

        syntax_validator.validate(path, report)

        if report.print_errors():
            success = False
            print(f'FAILED: {path}')
            continue

        if meta['database'] == 'vertica':
            if vertica_trino_flags & 1:
                vertica_validator.validate(path, meta['primary_subject'], report)
            if vertica_trino_flags & 2:
                trino_validator.validate(path, report)
        elif meta['database'] == 'clickhouse':
            clickhouse_validator.validate(path, report)

        if report.print_errors():
            success = False
            print(f'FAILED: {path}')
            continue

        report.print_metrics()
        report.print_warnings()

        if not report.print_exceed():
            print(f'PASSED: {path}')
        else:
            print(f'FAILED: {path}')

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
@click.option('--all', '-a', 'validate_all', is_flag=True, default=False)
@click.option('--limit0', '-0', 'limit0', type=str, is_flag=True, default=False)
@click.option('--n-days', '-d', 'n_days', type=int, default=1)
@click.option('--vertica-trino-flags', '-vt', 'vertica_trino_flags', type=int, default=3)
def main(filenames, limit0, n_days, validate_all, vertica_trino_flags):
    validate(filenames, limit0, n_days, validate_all, vertica_trino_flags)


if __name__ == '__main__':
    main()
