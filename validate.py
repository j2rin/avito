# -*- coding: utf-8 -*-

"""Скрипт валидации конфигураций метрик.

Отправляет запрос в валидационный API АБ Конфигуратора и выводит результат проверки в терминал.
"""

import json
import os


try:
    from http import client as httplib  # python 3
except ImportError:
    import httplib  # python 2


CUR_DIR_PATH = os.path.dirname(os.path.realpath(__file__))
PRESETS_PATH = os.path.join(CUR_DIR_PATH, 'ab_config_presets')
METRICS_FILE = os.path.join(CUR_DIR_PATH, 'config/metrics.yaml')

AB_CONFIGURATOR_HOST = 'ab-configurator.k.avito.ru'
METRICS_CONFIG_VALIDATOR_URL = '/api/validator/metrics_config/validate'
PRESETS_CONFIG_VALIDATOR_URL = '/api/validator/metrics_preset/validate'


def unroot(messages):
    return [x.get('root', x) if isinstance(x, dict) else x for x in messages]


def pretify(data):
    return json.dumps(data, indent=2, sort_keys=True)


def validate(file_name, url):
    print('\nValidating {}...'.format(file_name))

    conn = httplib.HTTPConnection(AB_CONFIGURATOR_HOST)

    with open(file_name, 'rb') as f:
        conn.request('POST', url, f)
        response = conn.getresponse()

    if response.status != 200:
        print('FAILED: Cannot connect to AB Configurator')
        exit(1)

    result = json.loads(response.read().decode())
    success = result['success']

    if not success:
        print('FAILED:')
        print(
            pretify(unroot(result['errors']))
        )

    elif 'warnings' in result:
        print('PASSED with warnings:')
        print(
            pretify(unroot(result['warnings']))
        )

    else:
        print('PASSED.\n')


if __name__ == '__main__':
    validate(METRICS_FILE, METRICS_CONFIG_VALIDATOR_URL)

    for preset_file_name in os.listdir(PRESETS_PATH):
        if preset_file_name.endswith('yaml'):
            validate(os.path.join(PRESETS_PATH, preset_file_name), PRESETS_CONFIG_VALIDATOR_URL)
