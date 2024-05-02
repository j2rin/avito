select
    track_id,
    event_no,
    event_date,
    cookie_id,
    user_id,
    platform_id,
    screen_name,
    metric_name,
    bytes_consumed
from dma.perf_screen_memory_consumption c
where cast(event_date as date) between :first_date and :last_date
--and event_month between date_trunc('month', :first_date) and date_trunc('month', :last_date) -- @trino

