create fact geo_map_labor as
select
    t.event_Date::date as __date__,
    t.cookie_id,
    t.event_Date,
    t.observation_name,
    t.observation_value
from dma.vo_geo_map_labor t
;

create metrics geo_map_labor as
select
    sum(case when observation_name = 'map_searches_to_btc_map' then observation_value end) as cnt_map_s_to_btc,
    sum(case when observation_name = 'map_searches_to_iv_map' then observation_value end) as cnt_map_s_to_iv
from geo_map_labor t
;
