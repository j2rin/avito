select
    track_id,
    event_no,
    event_date,
    cookie_id,
    user_id,
    platform_id,
    host,
    events_count,
    duration_sum
from dma.perf_queried_hosts_durations d
where cast(event_date as date) between :first_date and :last_date
--and event_month between date_trunc('month', :first_date) and date_trunc('month', :last_date) --@trino
