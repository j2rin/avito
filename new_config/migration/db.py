import vertica_python
from ruamel.yaml import YAML


VERTICA_SECRETS_PATH = '/etc/secrets/dwh/credentials.yaml'


def get_vertica_dsn(path, cluster, user):
    with open(path, 'r') as doc:
        yaml = YAML(typ='safe')
        cred = yaml.load(doc)
    return cred['vertica'][cluster][user]


def get_vertica_con(cluster, user):
    return vertica_python.connect(dsn=get_vertica_dsn(VERTICA_SECRETS_PATH, cluster, user))


