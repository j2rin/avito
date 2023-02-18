select
    track_id,
    event_no,
    event_date,
    event_timestamp,
    cookie_id,
    user_id,
    platform_id,
    eid,
    reviews_sort,
    profile_id
from dma.reviews_stream
where event_date::date between :first_date and :last_date
