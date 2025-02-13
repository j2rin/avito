select
    observation_date,
    cookie_id,
    user_id,
    platform_id,
    platform_name,
    network_type,
    screen_name,
    stage_name,
    events,
    events_p25,
    events_p50,
    events_p75,
    events_p95,
    events_sla,
    duration,
    duration_events,
    initial_page_render,
    max_duration,
    vertical_id
from dma.o_perf_web w
where cast(observation_date as date) between :first_date and :last_date
    -- and observation_week between date_trunc('week', :first_date) and date_trunc('week', :last_date) -- @trino
