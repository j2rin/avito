select
    cs.event_date::date,
    cs.cookie_id,
    cs.user_id,
    cs.platform_id,
    cs.useragent_id,
    cs.error_text,
    cs.error_type,
    cs.StackTrace,
    cs.eid
from dma.fatal_app_errors cs
where cs.event_date::date between :first_date and :last_date
