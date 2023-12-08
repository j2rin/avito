select
    observation_date,
    cookie_id,
    user_id,
    platform_id,
    platform_version,
    platform_name,
    app_version,
    network_type,
    screen_name,
    content_type,
    event_type,
    image_draw_type,
    image_class,
    events,
    events_p25,
    events_p50,
    events_p75,
    events_p95,
    duration,
    duration_events,
    exceptions,
    core_content_exceptions,
    image_host
from dma.o_image_mobile m
where cast(observation_date as date) between :first_date and :last_date
-- and observation_month between date_trunc('month', :first_date) and date_trunc('month', :last_date) -- @trino
