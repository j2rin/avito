import os
import cerberus
import yaml


METRICS_FILE = 'metrics.yaml'

CUR_DIR_PATH = os.path.dirname(os.path.realpath(__file__)) + '/'

CONFIG_PATH = CUR_DIR_PATH + 'config/'
SIGNIFICANCE_PARAMS_PATH = CUR_DIR_PATH + 'config/significance_params/'
SCHEMAS_PATH = CUR_DIR_PATH + 'config_schemas/'


def get_file(file_path):
    with open(file_path, 'r') as f:
        return f.read()


def get_yaml(file_path):
    return yaml.load(get_file(file_path))


def get_config(file_name):
    return get_yaml(CONFIG_PATH + file_name)


def get_schema(file_name):
    return get_yaml(SCHEMAS_PATH + file_name)


def validate_config():
    configs = dict()
    schemas = dict()

    for cn in [METRICS_FILE]:
        configs[cn] = get_config(cn)
        schemas[cn] = get_schema(cn)

#    for key in ['numerator', 'denominator']:
#        schemas[METRICS_FILE]['valueschema']['schema'][key]['allowed'] = observation_names

    significance_params = [f.split('.')[0] for f in os.listdir(SIGNIFICANCE_PARAMS_PATH)]

    schemas[METRICS_FILE]['valueschema']['schema']['significance_params']['allowed'] = significance_params

    validator = cerberus.Validator(schemas)
    # validator.allow_unknown = True
    if not validator.validate(configs):
        raise Exception(validator.errors)


if __name__ == '__main__':
    validate_config()
    print('All good!')
