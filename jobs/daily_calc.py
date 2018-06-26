import sys
import datetime
import pandas as pd

sys.path.append('/home/dlenkov/workspace/ab-metrics/metrics_calc/')
from metrics_calc import fill_data_storage_ab, get_all_ab_iters, AbItersStorage
from validator import validate_config
from log_helper import configure_logger
from settings import *


if __name__ == '__main__':
    logger = configure_logger(logger_name='metrics_calc', log_dir=CUR_DIR_PATH + 'log/')
    logger.info('metrics_calc started')

    validate_config()
    fill_data_storage_ab()

    logger.info('ab dicts loaded')
    ai = AbItersStorage()

    n_iters = len(ai.ab_iters)
    logger.info('{} iters to go'.format(n_iters))

    ai.fill_data_storage()

    logger.info('data_storage filled')

    try:
        n_fast_iters = len(ai.ab_iters_filtered())
        if n_fast_iters:
            logger.info('{} fast iters to go'.format(n_fast_iters))
            ai.calc_iters_by_type()

    except Exception as e:
        logger.error(e)
        raise e

    logger.info('All done!')
