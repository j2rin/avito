import json
import os
import requests
import shutil


CUR_DIR_PATH = os.path.dirname(os.path.realpath(__file__))


def clean_dir(dir_path):
    for filename in os.listdir(dir_path):
        file_path = os.path.join(dir_path, filename)
        try:
            if os.path.isfile(file_path) or os.path.islink(file_path):
                os.unlink(file_path)
            elif os.path.isdir(file_path):
                shutil.rmtree(file_path)
        except Exception as e:
            print('Failed to delete %s. Reason: %s' % (file_path, e))


def apply_mutations(file_content: str, mutations_config):
    if not mutations_config:
        return file_content
    fact_table_map = mutations_config.get('fact_table_map')
    result = file_content
    for old_table, new_table in fact_table_map.items():
        result = result.replace(old_table, new_table)
    return result


def main():
    url = 'https://ab.avito.ru/api/DumpDimetraConfigs'
    # url = 'http://127.0.0.1:5000/api/DumpDimetraConfigs'
    data = requests.post(url, json={}).json()

    dir_path = f'{CUR_DIR_PATH}/../dimetra/metrics_do_not_touch'
    clean_dir(dir_path)

    with open(f'{CUR_DIR_PATH}/dimetra_mutations.json') as f:
        all_mutations = json.load(f)

    for source_name, content in data['result'].items():
        with open(f'{dir_path}/{source_name}.sql', 'w') as f:
            mutations = all_mutations.get(source_name)
            to_write = apply_mutations(content, mutations)
            f.write(to_write)


if __name__ == '__main__':
    main()
