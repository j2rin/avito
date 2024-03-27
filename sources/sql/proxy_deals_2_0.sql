select 
    item_id
    , buyer_id as user_id
    , event_date
    , logical_category_id
    , vertical_id 
    , prob_adj
    , user_segment as user_segment_market
from 
    DMA.proxy_deals_2_0 
where cast(event_date as date) between cast(:first_date as date) and cast(:last_date as date)
-- and event_year between date_trunc('year', cast(:first_date as date)) and date_trunc('year', cast(:last_date as date)) -- @trino