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
where cast(event_date as date) between :first_date and :last_date
--and event_month between date_trunc('month', :first_date) and date_trunc('month', :last_date) --@trino
