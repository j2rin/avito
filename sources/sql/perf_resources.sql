select
    event_date,
    platform_id,
    cookie_id,
    user_id,
    screen_name,
    resource_type,
    location,
    value_raw,
    value
from dma.performance_resources_web w
where cast(event_date as date) between :first_date and :last_date
    -- and event_month between date_trunc('month', :first_date) and date_trunc('month', :last_date) -- @trino
