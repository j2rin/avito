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


def marks_to_str(file_name, data, marks_attribute):
    return '\n'.join(
        '{}:{} {}'.format(
            file_name,
            m['line'], m['message']
        )
        for m in data[marks_attribute]
    )


def validate(file_name, url, show_passed=False):
    conn = httplib.HTTPConnection(AB_CONFIGURATOR_HOST)

    with open(file_name, 'rb') as f:
        conn.request('POST', url, f)
        response = conn.getresponse()

    if response.status != 200:
        print('FAILED: Cannot connect to AB Configurator')
        exit(1)

    result = json.loads(response.read().decode())
    success = result['success']
    short_name = file_name.rsplit('/')[-1].rsplit('\\')[-1]

    if not success:
        print('\n{} FAILED:'.format(short_name))
        if 'error_marks' in result:
            print(
                marks_to_str(file_name, result, 'error_marks')
            )
        else:
            print(result['errors'])

    elif 'warnings' in result:
        print('\n{} PASSED with warnings:'.format(short_name))
        print(
            marks_to_str(file_name, result, 'warning_marks')
        )
    elif show_passed:
        print('\n{} PASSED'.format(short_name))


if __name__ == '__main__':
    validate(METRICS_FILE, METRICS_CONFIG_VALIDATOR_URL, show_passed=True)

    for preset_file_name in os.listdir(PRESETS_PATH):
        if preset_file_name.endswith('yaml'):
            validate(os.path.join(PRESETS_PATH, preset_file_name), PRESETS_CONFIG_VALIDATOR_URL)
