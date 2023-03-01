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
where event_date::date between :first_date and :last_date
