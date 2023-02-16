select
    event_date,
    cookie_id,
    user_id,
    screen_name,
    app_state,
    events,
    platform_id
from dma.o_perf_memory_warnings w
where event_date::date between :first_date and :last_date
