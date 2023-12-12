select
    track_id,
    event_no,
    event_date,
    event_timestamp,
    cookie_id,
    user_id,
    platform_id,
    2754 as eid,
    reviews_sort,
    profile_id, 
    case 
        when eid = 6372 and page_from = 'item' then 'item_scroll' 
        else page_from 
    end as page_from
from dma.reviews_stream
where cast(event_date as date) between :first_date and :last_date
    and not (eid = 2754 and coalesce(page_from,'none') in ('item_rating','item_scroll','item_all_reviews'))
    and not (eid = 2754 and coalesce(page_from,'none') = 'item' and platform_id = 3)
    --and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino

