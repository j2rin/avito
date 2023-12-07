select
    event_date,
    platform_id,
    cookie_id,
    x,
    x_eid,
    eid,
    item_rnk,
    mrr,
    map3,
    map5,
    map10
from dma.first_position_click
where cast(event_date as date) between :first_date and :last_date
--and event_month between date_trunc('month', :first_date) and date_trunc('month', :last_date) -- @trino
