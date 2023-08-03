select
    track_id,
    event_no,
    event_timestamp::date as event_date,
    event_timestamp,
    cookie_id,
    seller_id as user_id,
    business_platform as platform_id,
    eid,
    buyer_id as profile_id
from dma.buyer_reviews_stream
where event_timestamp::date between :first_date and :last_date