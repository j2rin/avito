import os

import trino
from trino.exceptions import TrinoUserError


def get_credentials():
    def get_from_env():
        return {
            'host': os.getenv(
                'TRINO_HOST',
                'dwh-ab-trino-coordinator-ef01',
            ),
            'user': os.getenv('TRINO_USER', 'ab_metrics'),
            # 'password': os.getenv('TRINO_PASSWORD', ''),
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
        return {'error': e.message}
    except Exception as e:
        raise e
    return {'is_valid': cur.fetchone()[0]}
