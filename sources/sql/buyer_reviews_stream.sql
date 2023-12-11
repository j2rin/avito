select
    track_id,
    event_no,
    cast(event_timestamp as date) as event_date,
    event_timestamp,
    cookie_id,
    seller_id as user_id,
    business_platform as platform_id,
    eid,
    buyer_id as profile_id
from dma.buyer_reviews_stream
where cast(event_timestamp as date) between :first_date and :last_date
    --and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
