select
    event_date,
    platform_id,
    cookie_id,
    vertical_id,
    logical_category_id,
    x_eid,
    eid,
    item_id,
    item_rnk,
    track_id,
    event_no
from dma.bs_first_click
where event_date::date between :first_date and :last_date
