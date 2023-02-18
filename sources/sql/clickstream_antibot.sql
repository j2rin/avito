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
where event_date::date between :first_date and :last_date