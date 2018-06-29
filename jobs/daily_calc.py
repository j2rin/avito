import sys
import datetime
import pandas as pd
import os

sys.path.append(os.environ['METRICS_CALC_PATH'])

from metrics_calc import fill_data_storage_ab, get_all_ab_iters, AbItersStorage, insert_breakdown_text_into_vertica, \
    logger
from validator import validate_config
from settings import *


if __name__ == '__main__':
    logger.info('metrics_calc started')

    validate_config()
    fill_data_storage_ab()
    logger.info('ab dicts loaded')
    insert_breakdown_text_into_vertica()
    logger.info('breakdowns texts inserted to vertica')

    ai = AbItersStorage()

    n_iters = len(ai.ab_iters)
    logger.info('{} iters total'.format(n_iters))
    ai.fill_data_storage()

    try:
        n_fast_iters = len(ai.ab_iters_filtered())
        if n_fast_iters:
            logger.info('{} fast iters total'.format(n_fast_iters))
            ai.calc_iters_by_type()

    except Exception as e:
        logger.error(e)
        raise e

    logger.info('All done!')
