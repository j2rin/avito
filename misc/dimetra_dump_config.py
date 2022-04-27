import os
import requests


CUR_DIR_PATH = os.path.dirname(os.path.realpath(__file__))


def main():
    data = requests.post('https://ab.avito.ru/api/DumpDimetraConfigs', json={}).json()
    for source_name, content in data['result'].items():
        with open(f'{CUR_DIR_PATH}/../dimetra/metrics/{source_name}.sql', 'w') as f:
            f.write(content)


if __name__ == '__main__':
    main()
