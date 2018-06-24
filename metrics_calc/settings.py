import os

USE_LOCAL = True

EVENTS_FILENAME = 'events'
OBSERVATIONS_FILENAME = 'observations'
METRICS_FILENAME = 'metrics'
DEFAULT_PARAMS_FILENAME = 'params_default'
DEFAULT_TEMPLATE = 'single_observation_sum'

SCRIPTS_FILENAME = 'scripts'

CUR_DIR_PATH = os.path.dirname(os.path.realpath(__file__)) + '/'

LOCAL_PATH = CUR_DIR_PATH + '../'
REMOTE_PATH = 'http://stash.msk.avito.ru/projects/BI/repos/ab-metrics/raw/'

CONFIG_RELATIVE_PATH = 'config/'
TEMPLATES_RELATIVE_PATH = 'config/metric_templates/'
PARAMS_RELATIVE_PATH = 'config/metric_params/'
SCHEMAS_RELATIVE_PATH = 'config_schemas/'

DATA_CACHE_PATH = CUR_DIR_PATH + 'data_cache.h5'

VERTICA_MAX_THREADS = 8