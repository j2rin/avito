import os
import cerberus
import yaml
from settings import CONFIG_PATH, SCHEMAS_PATH


def validate_config():
    def get_config(config_name):
        with open(CONFIG_PATH + '{}.yaml'.format(config_name), 'r') as f:
            return yaml.load(f)

    def get_schema(schema_name):
        with open(SCHEMAS_PATH + '{}.yaml'.format(schema_name), 'r') as f:
            return yaml.load(f)

    events_config = get_config('events')
    observations_config = get_config('observations')
    metrics_config = get_config('metrics')

    configs = dict()
    schemas = dict()

    for cn in ['events', 'observations', 'metrics']:
        configs[cn] = get_config(cn)
        schemas[cn] = get_schema(cn)

    schemas['observations']['valueschema']['schema']['events']['allowed'] = list(configs['events'].keys())
    schemas['metrics']['valueschema']['schema']['observations']['allowed'] = list(configs['observations'].keys())

    metric_params = [f.split('.')[0] for f in os.listdir(CONFIG_PATH + 'metric_params/')]
    metric_templates = [f.split('.')[0] for f in os.listdir(CONFIG_PATH + 'metric_templates/')]

    schemas['metrics']['valueschema']['schema']['params']['allowed'] = metric_params
    schemas['metrics']['valueschema']['schema']['template']['allowed'] = metric_templates

    validator = cerberus.Validator(schemas)
    if not validator.validate(configs):
        raise Exception(validator.errors)
