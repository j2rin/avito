import sys
import datetime
import pandas as pd

sys.path.append('/home/dlenkov/workspace/ab-metrics/metrics_calc/')
from metrics_calc import AbMetricsIters, AbMetrics, logger
from validator import validate_config
from db_utils import connect_vertica


def vertica_insert(df, tablename):
    df['insert_datetime'] = datetime.datetime.now()
    csv = df.to_csv(
        sep='^',
        index=False,
        header=False,
        float_format='%.16g'
    )
    columns_sql = ', '.join(df.columns)
    query = \
        "COPY {t} ({c}) from stdin DELIMITER '^' ABORT ON ERROR DIRECT;".format(t=tablename, c=columns_sql)
    with connect_vertica() as con:
        with con.cursor() as cur:
            cur.copy(query, csv)

if __name__ == '__main__':
    logger.info('metrics_calc started')

    validate_config()
    ai = AbMetricsIters()
    am = AbMetrics(ai.iters_to_do, 32)

    n_fast_iters = len(am.fast_ab_iters)

    if n_fast_iters:
        logger.info('{} fast iters to go'.format(n_fast_iters))
        df = pd.DataFrame.from_records(am.calc_fast_ab_iters, columns=am.calc_fast_ab_iters[0]._fields)
        vertica_insert(df, 'saef.ab_result')

    # if len(am.slow_ab_iters):
    #    df = pd.DataFrame.from_records(am.calc_slow_ab_iters, columns=am.calc_slow_ab_iters[0]._fields)
    #    vertica_insert(df, 'saef.ab_result')

    logger.info('All done!')
