import os
import cerberus
import yaml
import vertica_python
import warnings

warnings.filterwarnings('ignore')


METRICS_FILE = 'metrics.yaml'

CUR_DIR_PATH = os.path.dirname(os.path.realpath(__file__)) + '/'

CONFIG_PATH = CUR_DIR_PATH + 'config/'
SCHEMAS_PATH = CUR_DIR_PATH + 'config_schemas/'


AVAILABLE_OBSERVATIONS_SQL = """
select  observation_name
from (
    select  observation_name, rank() over(order by event_date desc) as rnk
    from    DMA.observations_directory
) d
where   rnk = 1
;"""


def get_available_observations(user=None, password=None):
    conn_info = {
        'host': 'vertica-dwh',
        'port': 5433,
        'database': 'DWH',
        'read_timeout': 3600,
        'user': user or 'tableau',
        'password': password or 'BestPushOnly166',
    }
    with vertica_python.connect(**conn_info) as con:
        with con.cursor('dict') as cur:
            cur.execute(AVAILABLE_OBSERVATIONS_SQL)
            return [r['observation_name'] for r in cur.fetchall()]


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

    available_observations = get_available_observations()
    schemas[METRICS_FILE]['valueschema']['schema']['numerator']['allowed'] = available_observations
    schemas[METRICS_FILE]['valueschema']['schema']['denominator']['allowed'] = available_observations

    validator = cerberus.Validator(schemas)
    # validator.allow_unknown = True
    if not validator.validate(configs):
        return validator.errors


if __name__ == '__main__':
    errors = validate_config()
    if errors:
        print(yaml.dump(errors))
    else:
        print('All good!')
