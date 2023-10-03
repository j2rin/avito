select max(traffic_source_agg) as value,
       traffic_source_agg_id       as value_id
from DICT.mrk_traffic_source_dict
group by traffic_source_agg_id
