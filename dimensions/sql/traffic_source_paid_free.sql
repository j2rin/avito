select max(traffic_source_paid_free) as value,
       traffic_source_paid_free_id as value_id
from DICT.mrk_traffic_source_dict
group by traffic_source_paid_free_id
