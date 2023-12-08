from ruamel.yaml import YAML

'''
Вспомогательные загрузчики инфы из YAML.
Важно их вызывать только после успеха `validate_configs()`
'''

SOURCES_YAML_PATH = 'sources/sources.yaml'


def get_sql_metadata():
    with open(SOURCES_YAML_PATH, 'r') as f:
        yaml = YAML(typ='safe', pure=True)
        doc_loaded = yaml.load(f)
    result = {}
    for source_name, source_meta in doc_loaded.items():
        sql_file_name = source_meta.get('sql')
        if not sql_file_name:
            continue
        subject = source_meta['primary_subject']
        result[sql_file_name] = {
            'primary_subject': source_meta['participant'][subject],
            'connections': source_meta['connections'],
        }

    return result
