select
    event_date,
    cookie_id,
    user_id,
    platform_id,
    vertical_id,
    category_id,
    is_human,
    is_participant_new,
    events,
    is_clean_cookie
from dma.o_clickstream_antibot
where cast(event_date as date) between :first_date and :last_date
--and event_week between date_trunc('week', :first_date) and date_trunc('week', :last_date) --@trino
