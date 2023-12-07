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
where cast(event_date as date) between :first_date and :last_date
--and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
