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

    @staticmethod
    def _make_sql(**kwargs):
        sql_template = kwargs['sql']
        params_keys = set(kwargs.keys())
        replacement_fields = retrieve_replacemnt_fields(sql_template)
        if not replacement_fields.issubset(params_keys):
            raise Exception(
                """
                Replacement fields in sql must be a subset of params' keys:
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

    def get_data(self, **kwargs):
        sql = self._make_sql(**kwargs)
        return super().get_data(sql)

    def get_observation(self, **kwargs):
        df = self.get_data(**kwargs)

        if df.shape[0] == 0:
            return

        obs_cols = kwargs['observations']
        dim_cols_set = set(df.index.names)
        kwargs_keys_set = set(kwargs.keys())
        if not dim_cols_set.issubset(kwargs_keys_set):
            raise Exception(
                """
                dim_cols in df must be a subset of kwargs' keys:
                — dim_cols: {dc}
                — kwargs' keys: {kk}
                — missing: {m}
                """.format(
                    dc=dim_cols_set,
                    kk=kwargs_keys_set,
                    m=dim_cols_set-kwargs_keys_set
                )
            )
        else:
            df_filtered = df.loc[tuple(kwargs[i] for i in df.index.names)]
            return {
                'obs': df_filtered[list(obs_cols)].values,
                'counts': df_filtered['cnt'].values,
            }

    def load_data_batch(self, iters_list, n_threads=1):
        sql_list = set([self._make_sql(**it) for it in iters_list])
        super().load_data_batch(sql_list, n_threads)
        for it in iters_list:
            sql = self._make_sql(**it)
            df = self.storage[sql]
            dim_cols = [c for c in df.columns if c not in list(it['observations']) + ['cnt']]
            self.storage.update({sql: df.set_index(dim_cols)})
