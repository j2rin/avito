select
    event_date,
	cookie_id,
    user_id,
    case 
        when platform_id = 1 then 'web'
        when platform_id = 2 then 'mav'
    end platform,
    eid,
    push_subscribe,
    cnt
from dma.web_mav_push_notifications
where true
	and cast(event_date as date) between :first_date and :last_date
    -- and date between :first_date and :last_date -- @trino
