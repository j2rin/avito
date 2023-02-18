select
    event_date,
    cookie_id,
    user_id,
    platform_id,
    startup_time_sum,
    startup_time_count,
    time_to_interact_sum,
    time_to_interact_count
from dma.o_perf_mobile_apps_startup_times
where event_date::date between :first_date and :last_date