select
    cast(cs.event_date as date) as event_date,
    cs.cookie_id,
    cs.user_id,
    cs.platform_id,
    cs.useragent_id,
    cs.error_text,
    cs.error_type,
    cs.StackTrace,
    cs.eid
from dma.fatal_app_errors cs
where cast(cs.event_date as date) between :first_date and :last_date
-- and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
