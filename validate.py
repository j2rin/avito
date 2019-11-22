# -*- coding: utf-8 -*-

"""Скрипт валидации конфигураций метрик.

Отправляет запрос в валидационный API АБ Конфигуратора и выводит результат проверки в терминал.
"""
from __future__ import unicode_literals

import json
import os

try:
    from http import client as httplib  # python 3
except ImportError:
    import httplib  # python 2


CUR_DIR_PATH = os.path.dirname(os.path.realpath(__file__))
PRESETS_PATH = os.path.join(CUR_DIR_PATH, 'ab_config_presets')
BREAKDOWNS_PRESETS_PATH = os.path.join(CUR_DIR_PATH, 'breakdown_presets')
METRICS_FILE = os.path.join(CUR_DIR_PATH, 'config/metrics.yaml')

AB_CONFIGURATOR_HOST = 'ab-configurator.k.avito.ru'
PRESETS_CONFIG_VALIDATOR_URL = '/api/validateMetricsRepo'


def marks_to_str(file_name, data, marks_attribute):
    return u'\n'.join(
        u'{}:{} {}'.format(
            file_name,
            m['line'],
            m['message']
        )
        for m in data[marks_attribute]
    )


def post(url, data):
    conn = httplib.HTTPConnection(AB_CONFIGURATOR_HOST)

    conn.request('POST', url, json.dumps(data).encode(), {'Content-Type': 'application/json'})

    response = conn.getresponse()

    text = response.read().decode()

    if response.status != 200:
        print('FAILED: Cannot connect to AB Configurator')
        print('status: {}'.format(response.status))
        print(text)
        exit(1)

    return json.loads(text)


def get_short_name(file_name):
    return file_name.rsplit('/')[-1].rsplit('\\')[-1]


def get_errors(result, file_name):
    if not result['success']:
        return False, (
            marks_to_str(file_name, result, 'error_marks')
            if 'error_marks' in result
            else result.get('errors')
        )

    if 'warnings' in result:
        return True, marks_to_str(file_name, result, 'warning_marks')

    return True, None


def show_errors(file_name_map, name, info):
    result = None
    fn = file_name_map[name]
    success, messages = get_errors(info, fn)

    if messages:
        short_fn = get_short_name(fn)

        if not success:
            print('\n{} FAILED:'.format(short_fn))
            result = name.rpartition('.')[0]
        else:
            print('\n{} PASSED with warnings:'.format(short_fn))

        if messages:
            print(messages)

    elif success and name == 'metrics':
        print('Metrics config PASSED')

    return result


def validate(url, config, presets):
    file_name_map = {x[0]: {} for x in presets}

    data = {
        'config': open(config).read()
    }

    for preset_type, path in presets:
        for fn in os.listdir(path):
            full_path = os.path.join(path, fn)
            if fn.endswith('.yaml'):
                short_name = get_short_name(fn)
                data[preset_type] = {
                    short_name: open(full_path).read()
                }

                file_name_map[preset_type][short_name] = full_path

    result = post(url, data)

    if result['success']:
        print('\nAll presets are PASSED')

    if 'errors' in result:
        print(result['errors'])
        return False

    failed_presets = {}

    info = result['result'].pop('config')
    show_errors({'config': METRICS_FILE}, 'config', info)

    if not info['success']:
        print('Metrics config presets IGNORED')
        return False

    for preset_type, _ in presets:
        for name, info in result['result'].get(preset_type, {}).items():
            failed = show_errors(file_name_map[preset_type], name, info)
            if failed:
                failed_presets.setdefault(preset_type, []).append(name)

    if not failed_presets:
        print('\nAll presets are PASSED')
    else:
        for preset_type, names in failed_presets.items():
            print('\nFAILED {} presets: {}'.format(preset_type, ', '.join(sorted(names))))

    return True


if __name__ == '__main__':
    success = validate(
        PRESETS_CONFIG_VALIDATOR_URL,
        METRICS_FILE,
        [
            ('breakdown_presets', BREAKDOWNS_PRESETS_PATH),
            ('ab_config_presets', PRESETS_PATH),
        ]
    )

    if not success:
        exit(1)