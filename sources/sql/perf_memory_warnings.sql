select
    event_date,
    cookie_id,
    user_id,
    screen_name,
    app_state,
    events,
    platform_id
from dma.o_perf_memory_warnings w
where cast(event_date as date) between :first_date and :last_date
