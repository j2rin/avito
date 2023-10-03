select max(traffic_source) as value,
       traffic_source_id as value_id
from DICT.mrk_traffic_source_dict
group by traffic_source_id
