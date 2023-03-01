import os

from clickhouse_driver import Client


def get_clickhouse_credentials():
    def get_from_env():
        return {
            'host': os.getenv(
                'CLICKHOUSE_HOST',
                'clickhouse-tcp-clickhouse-dwh-cs-production-rs-rs01.db.avito-sd',
            ),
            'database': os.getenv('CLICKHOUSE_DATABASE', 'dwh'),
            'user': os.getenv('CLICKHOUSE_USER', ''),
            'password': os.getenv('CLICKHOUSE_PASSWORD', ''),
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
    return Client(**get_clickhouse_credentials())


def get_query_columns(con, sql):
    """Возвращает типы колонок из запроса."""
    sql = sql.strip(' \n;') + ' limit 0'
    result = con.execute(sql, with_column_types=True)
    return {col: typ for col, typ in result[1]}
