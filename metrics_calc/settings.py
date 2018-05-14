import os

USE_LOCAL = True

EVENTS_FILENAME = 'events'
OBSERVATIONS_FILENAME = 'observations'
METRICS_FILENAME = 'metrics'

CUR_DIR_PATH = os.path.dirname(os.path.realpath(__file__))

CONFIG_PATH = CUR_DIR_PATH + '/../config/'
SCHEMAS_PATH = CUR_DIR_PATH + '/../config_schemas/'
TEMPLATES_PATH = CUR_DIR_PATH + '/../config/metric_templates/'
PARAMS_PATH = CUR_DIR_PATH + '/../config/metric_params/'

DEFAULT_PARAMS_FILENAME = 'params_default'

DEFAULT_TEMPLATE = 'single_observation_sum'
