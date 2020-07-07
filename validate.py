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
from time import sleep

try:
    from http import client as httplib  # python 3
except ImportError:
    import httplib  # python 2


AB_CONFIGURATOR_HOST = 'ab.avito.ru'
VALIDATE_URL = '/api/validateMetricsRepo'
PUBLISH_URL = '/api/publishMetricsRepo'


CUR_DIR_PATH = os.path.dirname(os.path.realpath(__file__))


# Конфиги, которые необходимо отправить в конфигуратор.
# Формат: (<имя поля в json>, <путь к файлу/директории>, <является ли путь директорией>)
CONFIGS = [
    ('sources', os.path.join(CUR_DIR_PATH, 'new_config/sources.yaml'), False),
    ('configs', os.path.join(CUR_DIR_PATH, 'new_config/metrics'), True),
    ('ratio_configs', os.path.join(CUR_DIR_PATH, 'new_config/metrics/ratio'), True),
    ('breakdown_presets', os.path.join(CUR_DIR_PATH, 'presets/breakdowns'), True),
    ('ab_config_presets', os.path.join(CUR_DIR_PATH, 'presets'), True),
    ('metrics_lists', os.path.join(CUR_DIR_PATH, 'presets/metrics'), True),
    ('m42_dimensions', os.path.join(CUR_DIR_PATH, 'config/m42.yaml'), False),
    ('m42_subscriptions', os.path.join(CUR_DIR_PATH, 'config/metrics_subscriptions.yaml'), False),
]


def validate():
    result, file_name_maps = send_all(VALIDATE_URL)

    if result['success']:
        print('\nAll PASSED')

    if 'errors' in result:
        print(result['errors'])
        return False

    failed_configs = {}

    for config_name, _, is_multi in CONFIGS:
        fn_map = file_name_maps[config_name]

        validation_results = (
            result['result'].get(config_name, {}).items()
            if is_multi
            else [(config_name, result['result'].get(config_name, {}))]
        )
        for file_name, info in validation_results:
            failed = show_errors(fn_map, file_name, info)
            if failed:
                failed_configs.setdefault(config_name, []).append(file_name)

        if not failed_configs:
            print('\nAll PASSED')
        else:
            for preset_type, names in failed_configs.items():
                print('\nFAILED {}: {}'.format(preset_type, ', '.join(sorted(names))))
            return False

    return True


def process():
    result, _, _ = send_all(PROCESS_URL)
    print(
        json.dumps(result, indent=4)
    )


def publish():
    key = os.getenv('API_KEY')

    if not key:
        print('No API_KEY in the env')
        exit(2)

    result, _ = send_all(PUBLISH_URL, os.getenv('API_KEY'))

    if not result.get('success'):
        print('Cannot publish metrics config')
        print(result)
        exit(1)

    print('Metrics repo has been successfully updated')


def send_all(url, api_key=None):
    data = {}
    file_name_maps = {}

    if api_key:
        data['api_key'] = api_key

    for name, path, is_multi in CONFIGS:
        if is_multi:
            data[name], file_name_maps[name] = read_yamls(path)
        else:
            data[name] = read_file(path)
            file_name_maps[name] = {name: path}

    result = post(url, data)
    return result, file_name_maps


def post(url, data):
    def _post():
        #conn = httplib.HTTPConnection('127.0.0.1', 5000)
        conn = httplib.HTTPSConnection(AB_CONFIGURATOR_HOST)

        conn.request('POST', url, json.dumps(data).encode(), {'Content-Type': 'application/json'})

        response = conn.getresponse()
        return response.status, response.read().decode()

    status, text = _post()

    # retry on gateway timeout
    for i in range(3):
        if status != 504:
            break
        print('Gateway timeout, retrying...')
        sleep(i * 30)
        status, text = _post()

    if status != 200:
        print('FAILED: Cannot connect to AB Configurator')
        print('status: {}'.format(status))

        try:
            print(json.loads(text)['errors'])
        except Exception:
            print(text)

        exit(1)

    return json.loads(text)


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


def read_file(file_path: str):
    return io.open(file_path, encoding='utf-8').read()


def read_yamls(dir_path):
    file_name_map = {}
    result = {}

    for fn in os.listdir(dir_path):
        if fn.endswith('.yaml') and not fn.startswith('_'):
            full_path = os.path.join(dir_path, fn)
            short_name = get_short_name(fn)
            result[short_name] = read_file(full_path)

            file_name_map[short_name] = full_path
    return result, file_name_map


def get_errors(result, file_name):
    def marks_to_str(file_name, data, marks_attribute):
        return u'\n'.join(
            u'{}:{} {}'.format(
                file_name,
                m['line'],
                m['message']
            )
            for m in data[marks_attribute]
        )
    if not result['success']:
        return False, (
            marks_to_str(file_name, result, 'error_marks')
            if 'error_marks' in result
            else result.get('errors')
        )

    if 'warnings' in result:
        return True, marks_to_str(file_name, result, 'warning_marks')

    return True, None


def get_short_name(file_name):
    return file_name.rsplit('/')[-1].rsplit('\\')[-1].rsplit('.')[0]


if __name__ == '__main__':
    if len(sys.argv) == 2:
        if sys.argv[1] == '--process':
            process()
            exit(0)
        elif sys.argv[1] == '--publish':
            publish()
            exit(0)
        else:
            print('Unknown argument')
            exit(1)

    success = validate()

    if not success:
        exit(1)
