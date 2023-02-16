from ruamel.yaml import safe_load

'''
Вспомогательные загрузчики инфы из YAML.
Важно их вызывать только после успеха `validate_configs()`
'''

SOURCES_YAML_PATH = 'sources/sources.yaml'


def get_sql_primary_subject_map():
    with open(SOURCES_YAML_PATH, 'r') as f:
        doc_loaded = safe_load(f)

    result = {}
    for source_name, source_meta in doc_loaded.items():
        sql_file_name = source_meta.get('sql')
        if not sql_file_name:
            continue
        subject = source_meta['primary_subject']
        result[sql_file_name] = source_meta['participant'][subject]

    return result
