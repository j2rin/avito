import os
import cerberus
import yaml
from utils import get_config, get_schema
from settings import *


def validate_config():
    configs = dict()
    schemas = dict()

    for cn in [EVENTS_FILENAME, OBSERVATIONS_FILENAME, METRICS_FILENAME]:
        configs[cn] = get_config(cn)
        schemas[cn] = get_schema(cn)

    schemas[OBSERVATIONS_FILENAME]['valueschema']['schema']['events']['allowed'] = \
        list(configs[EVENTS_FILENAME].keys())
    schemas[METRICS_FILENAME]['valueschema']['schema']['observations']['allowed'] = \
        list(configs[OBSERVATIONS_FILENAME].keys())

    metric_params = [f.split('.')[0] for f in os.listdir(LOCAL_PATH + PARAMS_RELATIVE_PATH)]
    metric_templates = [f.split('.')[0] for f in os.listdir(LOCAL_PATH + TEMPLATES_RELATIVE_PATH)]

    schemas[METRICS_FILENAME]['valueschema']['schema']['params']['allowed'] = metric_params
    schemas[METRICS_FILENAME]['valueschema']['schema']['template']['allowed'] = metric_templates

    validator = cerberus.Validator(schemas)
    if not validator.validate(configs):
        raise Exception(validator.errors)
