# -*- coding: utf-8 -*-


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

CUR_DIR_PATH = os.path.dirname(os.path.realpath(__file__))
CONFIGS_PATH = CUR_DIR_PATH
METRICS_PATH = os.path.join(CONFIGS_PATH, 'metrics')

AB_CONFIGURATOR_HOST = 'ab.avito.ru'

VALIDATE_URL = '/api/validateMetricsConfigs'
PROCESS_URL = '/api/processMetricsConfigs'
PUBLISH_URL = '/api/publishMetricsConfigs'


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
    def _post():
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


def send_all(url):
    data = {
        'sources': io.open(os.path.join(CONFIGS_PATH, 'sources.yaml'), encoding='utf-8').read(),
        'configs': {}
    }
    file_name_map = {}

    for fn in os.listdir(METRICS_PATH):
        full_path = os.path.join(METRICS_PATH, fn)
        if fn.endswith('.yaml') and not fn.startswith('_'):
            short_name = get_short_name(fn)
            data['configs'][short_name] = io.open(full_path, encoding='utf-8').read()

            file_name_map[short_name] = full_path

    result = post(url, data)
    return result, file_name_map


def validate():
    result, file_name_map = send_all(VALIDATE_URL)
    if not result['sources']['success']:
        show_errors({'sources': os.path.join(CONFIGS_PATH, 'sources.yaml')}, 'sources', result['sources'])
        return False

    ok = True
    for name in result['configs']:
        if not result['configs'][name]['success']:
            show_errors(file_name_map, name, result['configs'][name])
            ok = False

    return ok


def process():
    result, _ = send_all(PROCESS_URL)
    print(
        json.dumps(result, indent=4)
    )


def publish():
    send_all(PUBLISH_URL)


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
