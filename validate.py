# -*- coding: utf-8 -*-

"""Скрипт валидации конфигураций метрик.

Отправляет запрос в валидационный API АБ Конфигуратора и выводит результат проверки в терминал.

Внезапно этот же скрипт используется для отправки пресетов и конфига из CI в конфигуратор.
"""
from __future__ import unicode_literals

import io
import json
import os
import sys

try:
    from http import client as httplib  # python 3
except ImportError:
    import httplib  # python 2


CUR_DIR_PATH = os.path.dirname(os.path.realpath(__file__))
PRESETS_PATH = os.path.join(CUR_DIR_PATH, 'presets')
BREAKDOWNS_PRESETS_PATH = os.path.join(CUR_DIR_PATH, 'presets/breakdowns')
METRICS_LISTS_PATH = os.path.join(CUR_DIR_PATH, 'presets/metrics')
METRICS_FILE = os.path.join(CUR_DIR_PATH, 'config/metrics.yaml')
METRICS_DIMENSION_FILE = os.path.join(CUR_DIR_PATH, 'config/m42.yaml')
METRICS_SUBSCRIPTION_FILE = os.path.join(CUR_DIR_PATH, 'config/metrics_subscriptions.yaml')

AB_CONFIGURATOR_HOST = 'ab.avito.ru'
PRESETS_CONFIG_VALIDATE_URL = '/api/validateMetricsRepo'
PRESETS_CONFIG_PUBLISH_URL = '/api/publishMetricsRepo'


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
    conn = httplib.HTTPSConnection(AB_CONFIGURATOR_HOST)

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
    return file_name.rsplit('/')[-1].rsplit('\\')[-1].rsplit('.')[0]


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
    result = False
    fn = file_name_map[name]
    success, messages = get_errors(info, fn)

    if messages:
        short_fn = get_short_name(fn)

        if not success:
            print('\n{} FAILED:'.format(short_fn))
            result = True
        else:
            print('\n{} PASSED with warnings:'.format(short_fn))

        if messages:
            print(messages)

    elif success and name == 'metrics':
        print('Metrics config PASSED')

    return result


def send_all(url, config, presets, dimensions, subscriptions, api_key=None):

    file_name_map = {x[0]: {} for x in presets}
    data = {
        'config': io.open(config, encoding='utf-8').read()
    }

    data['m42_dimensions'] = io.open(dimensions, encoding='utf-8').read()
    data['m42_subscriptions'] = io.open(subscriptions, encoding='utf-8').read()

    if api_key:
        data['api_key'] = api_key

    for preset_type, path in presets:
        data[preset_type] = {}

        for fn in os.listdir(path):
            full_path = os.path.join(path, fn)
            if fn.endswith('.yaml'):
                short_name = get_short_name(fn)
                data[preset_type][short_name] = io.open(full_path, encoding='utf-8').read()

                file_name_map[preset_type][short_name] = full_path

    result = post(url, data)
    return result, file_name_map


def validate(url, config, presets, dimensions, subscriptions):
    result, file_name_map = send_all(url, config, presets, dimensions, subscriptions)


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

    info_dimensions = result['result'].pop('m42_dimensions')
    
    show_errors({'m42_dimensions': METRICS_DIMENSION_FILE}, 'm42_dimensions', info_dimensions)

    if not info['success']:
        print('Metrics dimensions config presets IGNORED')
        return False

    info_subscriptions = result['result'].pop('m42_subscriptions')

    show_errors({'m42_subscriptions': METRICS_SUBSCRIPTION_FILE}, 'm42_subscriptions', info_subscriptions)

    if not info['success']:
        print('Metrics subscriptions config IGNORED')
        return False

    for preset_type, _ in presets:
        for name, info in result['result'].get(preset_type, {}).items():
            failed = show_errors(file_name_map[preset_type], name, info)
            if failed:
                failed_presets.setdefault(preset_type, []).append(name)

    if not failed_presets:
        print('\nAll presets are PASSED')
        return True

    for preset_type, names in failed_presets.items():
        print('\nFAILED {} presets: {}'.format(preset_type, ', '.join(sorted(names))))

    return False


def publish_repo():
    key = os.getenv('API_KEY')

    if not key:
        print('No API_KEY in the env')
        exit(2)

    result, _ = send_all(
        PRESETS_CONFIG_PUBLISH_URL,
        METRICS_FILE,
        [
            ('breakdown_presets', BREAKDOWNS_PRESETS_PATH),
            ('ab_config_presets', PRESETS_PATH),
            ('metrics_lists', METRICS_LISTS_PATH),
        ],
        METRICS_DIMENSION_FILE,
        METRICS_SUBSCRIPTION_FILE,
        os.getenv('API_KEY')
    )

    if not result.get('success'):
        print('Cannot publish metrics config')
        print(result)
        exit(1)

    print('Metrics repo has been successfully updated')


def validate_repo():
    success = validate(
        PRESETS_CONFIG_VALIDATE_URL,
        METRICS_FILE,
        [
            ('breakdown_presets', BREAKDOWNS_PRESETS_PATH),
            ('ab_config_presets', PRESETS_PATH),
            ('metrics_lists', METRICS_LISTS_PATH),
        ],
        METRICS_DIMENSION_FILE,
        METRICS_SUBSCRIPTION_FILE
    )

    if not success:
        exit(1)


if __name__ == '__main__':
    if len(sys.argv) == 2 and sys.argv[1] == '--publish':
        publish_repo()
    else:
        validate_repo()
