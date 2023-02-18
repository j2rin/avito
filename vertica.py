import os

import vertica_python


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


def get_vertica_con():
    return vertica_python.connect(**get_vertica_credentials())


def get_query_columns(con, sql):
    sql_limit0 = f'select * from ({sql}) _\nlimit 0'
    with con.cursor() as cur:
        cur.execute(sql_limit0)
        return cur.description
