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
where event_date::date between :first_date and :last_date