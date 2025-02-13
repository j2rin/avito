import os
from datetime import datetime

import trino
from trino.exceptions import TrinoUserError


def get_credentials():
    def get_from_env():
        user = os.getenv('TRINO_USER', 'ab_metrics')
        password = os.getenv('TRINO_PASSWORD', '')
        return {
            'auth': trino.auth.BasicAuthentication(user, password),
            'host': os.getenv(
                'TRINO_HOST',
                'dwh-ab-trino.k.avito.ru',
            ),
            'port': os.getenv('TRINO_PORT', '443'),
            'http_scheme': os.getenv('TRINO_HTTP_SCHEMA', 'https'),
            'catalog': os.getenv('TRINO_CATALOG', 'dwh'),
            'schema': os.getenv('TRINO_SCHEMA', 'dwh'),
        }

    from_env = get_from_env()
    if not from_env['user']:
        # Если не нашлись креды, пробуем загрузить из файла `.env`
        # Для удобства локального запуска
        from dotenv import load_dotenv

        load_dotenv()
        return get_from_env()
    return from_env


def get_connection():
    return trino.dbapi.connect(**get_credentials())


def explain_validate(con, sql):
    sql_explain = f'EXPLAIN (TYPE VALIDATE) {sql}'
    cur = con.cursor()
    try:
        cur.execute(sql_explain)
    except TrinoUserError as e:
        return {'error': e}
    except Exception as e:
        raise e
    return {'is_valid': cur.fetchone()[0]}


def explain_analyze(con, sql):
    sql_explain = f'EXPLAIN ANALYZE {sql}'
    cur = con.cursor()
    try:
        start = datetime.now()
        cur.execute(sql_explain)
        duration = (datetime.now() - start).total_seconds()
    except TrinoUserError as e:
        return {'error': e}
    except Exception as e:
        raise e
    return {'duration': duration}
