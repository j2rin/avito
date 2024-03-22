select 
    pd20.item_id
    , pd20.buyer_id as user_id
    , pd20.event_date
    , clc.logical_category_id
    , clc.vertical_id 
    , pd20.prob_adj
    , pd20.user_segment as user_segment_market
from 
    DMA.proxy_deals_2_0 pd20
left join DMA.current_item as ci
    on pd20.item_id = ci.item_id
left join infomodel.current_infmquery_category as cic
    on ci.infmquery_id = cic.infmquery_id
left join dma.current_logical_categories as clc
    on cic.logcat_id = clc.logcat_id
where cast(pd20.event_date as date) between :first_date and :last_date

