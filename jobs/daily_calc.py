import sys
import datetime
import pandas as pd

sys.path.append('/home/dlenkov/workspace/ab-metrics/metrics_calc/')
from metrics_calc import fill_data_storage_ab, get_all_ab_iters, AbItersStorage
from validator import validate_config
from db_utils import insert_into_vertica
from log_helper import configure_logger
from settings import *


if __name__ == '__main__':
    logger = configure_logger(logger_name='metrics_calc', log_dir=CUR_DIR_PATH + 'log/')

    logger.info('metrics_calc started')

    validate_config()

    fill_data_storage_ab()

    logger.info('ab dicts loaded')

    its = get_all_ab_iters()
    ai = AbItersStorage(its)

    try:
        ai.fill_data_storage()
    except Exception as e:
        logger.error(e)
        raise e

    logger.info('data_storage filled')

    n_fast_iters = len(ai.ab_iters_filtered())

    if n_fast_iters:
        logger.info('{} fast iters to go'.format(n_fast_iters))
        records = ai.calc_iters_by_type()
        df = pd.DataFrame.from_records(records)
        insert_into_vertica(df, 'saef.ab_result')

    # if len(am.slow_ab_iters):
    #    df = pd.DataFrame.from_records(am.calc_slow_ab_iters, columns=am.calc_slow_ab_iters[0]._fields)
    #    vertica_insert(df, 'saef.ab_result')

    logger.info('All done!')
