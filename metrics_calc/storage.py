from _string import formatter_field_name_split
from string import Formatter
from db_utils import connect_postgre, connect_vertica, VerticaStorage
from collections import namedtuple


def retrieve_replacemnt_fields(format_string):
    return {
        formatter_field_name_split(fname)[0]
        for _, fname, _, _ in Formatter().parse(format_string) if fname
    }


class ObservationsStorage(VerticaStorage):

    def _make_sql(self, **kwargs):
        assert 'sql_template' in kwargs
        sql_template = kwargs['sql_template']
        params_keys = set(kwargs.keys())
        _replacement_fields = retrieve_replacemnt_fields(sql_template)
        if not _replacement_fields.issubset(params_keys):
            raise Exception(
                """
                Replacement fields in sql_template must be a subset of params' keys:
                — replacement_fields: {rf}
                — params keys: {pk}
                — missing: {m}
                """.format(
                    rf=replacement_fields,
                    pk=params_keys,
                    m=replacement_fields-params_keys
                )
            )
        else:
            return sql_template.format(**kwargs)

    def get_observation(self, **kwargs):
        sql = self._make_sql(**kwargs)
        df = self.get_data(sql)
        if df.shape[0] == 0:
            return
        obs_cols = [c for c in df.columns if c not in ['split_group_id', 'cnt']]
        return {
            sg: {
                    'obs': df[df.split_group_id == sg][obs_cols].values,
                    'counts': df[df.split_group_id == sg]['cnt'].values
            }
            for sg in df.split_group_id.unique()
        }

    def load_observations_batch(self, iters_list, n_threads=1):
        sql_list = [self._make_sql(**it) for it in iters_list]
        self.load_data_batch(sql_list, n_threads)
