from db import get_vertica_con
import pandas as pd


METRICS_CONFIG_SQL = """
with metric_sources as (
    select metric_name, max(case when component = 'numerator' then sources end) as num_sources,
            max(case when component = 'denominator' then sources end) as den_sources,
            listagg(ifnull(sources, '') using parameters max_size=256) as sources
    from (
        select metric_name, component, listagg(ifnull(observation_source, '') using parameters max_size=256) as sources, count(observation_source) as sources_cnt
        from (
            SELECT distinct mf.metric_name, mf.component, od.observation_source
            FROM DMA.v_metric_constructor   mf
            left JOIN DMA.observations_directory od ON od.observation_name = mf.observation_name
            WHERE event_date::date = '{calc_date}'
            order by 1, 2
            limit 1000000
        ) o
        group by 1, 2
    ) s
    group by 1
)
select  *
from    dma.v_metrics_config
left join metric_sources using (metric_name)
;
"""

OBSERVATION_DIR_SQL = """
SELECT od.observation_name as obs, od.observation_source as source
FROM   DMA.observations_directory od
WHERE event_date::date = '{calc_date}'
group by 1, 2
;
"""


def load_metadata(calc_date, csv_name, sql):
    # try:
    #     return pd.read_csv(csv_name).fillna('')
    # except Exception:
    with get_vertica_con('C3', 'avkarpova') as con:
        frame = pd.read_sql(sql.format(calc_date=calc_date), con).fillna('')
        frame.to_csv(csv_name, index=False)
        return pd.read_csv(csv_name).fillna('')


def load_metrics_config(calc_date):
    return load_metadata(calc_date, 'metric_config.csv', METRICS_CONFIG_SQL)


def load_observations_directory(calc_date):
    return load_metadata(calc_date, 'observations_directory.csv', OBSERVATION_DIR_SQL)


if __name__ == '__main__':
    print(load_observations_directory('2020-05-26'))
