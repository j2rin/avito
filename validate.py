# -*- coding: utf-8 -*-

"""Скрипт валидации конфигураций метрик.

Отправляет запрос в валидационный API АБ Конфигуратора и выводит результат проверки в терминал.

Внезапно этот же скрипт используется для отправки пресетов и конфига из CI в конфигуратор.
"""

import io
import json
import os
import sys
from http import client as httplib
from time import sleep

from dotenv import load_dotenv

load_dotenv()

AB_CONFIGURATOR_HOST = 'ab.avito.ru'
VALIDATE_URL = '/api/validateMetricsRepo'
PRODUCTION_BRANCH = 'origin/master'


CUR_DIR_PATH = os.path.dirname(os.path.realpath(__file__))


# Конфиги, которые необходимо отправить в конфигуратор.
# Формат: (<имя поля в json>, <путь к файлу/директории>, <является ли путь директорией>)
CONFIGS = [
    ('sources', os.path.join(CUR_DIR_PATH, 'sources/sources.yaml'), False),
    ('sources_sql', os.path.join(CUR_DIR_PATH, 'sources/sql'), True),
    ('dimensions', os.path.join(CUR_DIR_PATH, 'dimensions/dimensions.yaml'), False),
    ('dimensions_sql', os.path.join(CUR_DIR_PATH, 'dimensions/sql'), True),
    ('configs', os.path.join(CUR_DIR_PATH, 'metrics'), True),
    ('m42_cartesian_groups', os.path.join(CUR_DIR_PATH, 'm42_cartesian_groups'), True),
]


def list_modified_files():
    result = []

    # Для локального запуска
    from git import Repo

    repo = Repo('.')
    origin_master = repo.commit(PRODUCTION_BRANCH)
    for item in origin_master.diff(None):
        result.append(item.a_path)

    return result


def validate_configs():
    result, file_name_maps = send_all(VALIDATE_URL)

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

    success = result['success']

    if success:
        print('\nYAML validation PASSED')
    elif not failed_configs:
        print('unknown error')
    else:
        for preset_type, names in failed_configs.items():
            print('\nFAILED {}: {}'.format(preset_type, ', '.join(sorted(names))))

    return success


def validate():

    try:
        success = validate_configs()

    except Exception as e:
        success = False
        print(e)

    if success:
        print('\nValidation PASSED')
        exit(0)
    else:
        print('\nValidation FAILED')
        exit(1)


def send_all(url):
    data = {}
    file_name_maps = {}
    changed_files = list_modified_files()
    for name, path, is_multi in CONFIGS:
        if is_multi:
            data[name], file_name_maps[name] = read_configs(path, changed_files)
        else:
            data[name] = read_file(path)
            file_name_maps[name] = {name: path}

    result = post(url, data)
    return result, file_name_maps


def post(url, data):
    def _post():
        # conn = httplib.HTTPConnection('127.0.0.1', 5000)
        conn = httplib.HTTPSConnection(AB_CONFIGURATOR_HOST)

        conn.request('POST', url, json.dumps(data).encode(), {'Content-Type': 'application/json'})

        response = conn.getresponse()
        return response.status, response.read().decode()

    status, text = _post()

    # retry on gateway timeout
    for i in range(10):
        if status != 504:
            break
        print('Gateway timeout, retrying...')
        sleep(i * 30)
        status, text = _post()

    if status != 200:
        print('FAILED: Unhandled error')
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


def read_file(file_path):
    return io.open(file_path, encoding='utf-8').read()


def read_configs(dir_path, changed_files):
    file_name_map = {}
    result = {}

    def is_file_appropriate(fn):
        return (
            fn.endswith('.yaml')
            or fn.endswith('.yml')
            or fn.endswith('.sql')
            and not fn.startswith('_')
        )

    for fn in os.listdir(dir_path):
        if is_file_appropriate(fn):
            full_path = os.path.join(dir_path, fn)
            short_name = get_short_name(fn)
            result[short_name] = (read_file(full_path), full_path.replace(f'{CUR_DIR_PATH}/', '') in changed_files)

            file_name_map[short_name] = full_path
    return result, file_name_map


def get_errors(result, file_name):
    def marks_to_str(file_name, data, marks_attribute):
        return u'\n'.join(
            u'{}:{} {}'.format(file_name, m['line'], m['message']) for m in data[marks_attribute]
        )

    if not result.get('success'):
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
        if sys.argv[1] == '--validate-staging':
            AB_CONFIGURATOR_HOST = 'staging.k.avito.ru'
            VALIDATE_URL = '/service-ab-configurator' + VALIDATE_URL

            validate()
            exit(0)
        else:
            print('Unknown argument')
            exit(1)

    validate()
