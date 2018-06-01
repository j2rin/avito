import pandas as pd
from functools import lru_cache
import yaml
from settings import *


@lru_cache(maxsize=None)
def get_file(relative_path, filename):
    if USE_LOCAL:
        url = LOCAL_PATH + relative_path + filename
        with open(url, 'r') as f:
            return f.read()
    else:
        url = REMOTE_PATH + relative_path + filename
        with requests.get(url) as r:
            return r.text


def get_yaml(config_path, filename):
    return yaml.load(get_file(config_path, filename + '.yaml'))


def get_config(filename):
    return get_yaml(CONFIG_RELATIVE_PATH, filename)


def get_params(filename):
    return get_yaml(PARAMS_RELATIVE_PATH, filename)


def uniquify_dicts(dicts):
    set_of_tuples = set(tuple(set(d.items())) for d in dicts)
    return [{k: v for k, v in d} for d in set_of_tuples]


def get_schema(filename):
    return get_yaml(SCHEMAS_RELATIVE_PATH, filename)


def get_sql(script_name):
    url = CUR_DIR_PATH + SCRIPTS_FILENAME + '.sql'
    with open(url, 'r') as f:
        return yaml.load(f)[script_name]


def get_template(filename):
    return get_file(TEMPLATES_RELATIVE_PATH, filename + '.sql')


def uniquify_dicts(dicts):
    set_of_tuples = set(tuple(set(d.items())) for d in dicts)
    return [{k: v for k, v in d} for d in set_of_tuples]
