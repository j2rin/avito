select
    event_date,
	cookie_id,
    user_id,
    platform_id,
    eid,
    push_subscribe,
    cnt
from dma.web_mav_push_notifications
where true
	and cast(event_date as date) between :first_date and :last_date
    -- and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
