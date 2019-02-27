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
METRICS_FILE = os.path.join(CUR_DIR_PATH, 'config/metrics.yaml')

AB_CONFIGURATOR_HOST = 'ab-configurator.k.avito.ru'
METRICS_CONFIG_VALIDATOR_URL = '/api/validator/metrics_config/validate'


def unroot(messages):
    return [x.get('root', x) for x in messages]


def pretify(data):
    return json.dumps(data, indent=2, sort_keys=True)


if __name__ == '__main__':
    print('Validating {}...\n'.format(METRICS_FILE))

    conn = httplib.HTTPConnection(AB_CONFIGURATOR_HOST)

    with open(METRICS_FILE, 'rb') as f:
        conn.request('POST', METRICS_CONFIG_VALIDATOR_URL, f)
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
        print('PASSED.')
