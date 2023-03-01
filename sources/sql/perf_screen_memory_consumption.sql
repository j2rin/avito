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
where event_date::date between :first_date and :last_date

