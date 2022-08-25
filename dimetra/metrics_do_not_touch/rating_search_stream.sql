create fact rating_search_stream as
select
    t.event_date::date as __date__,
    *
from dma.vo_rating_search_stream t
;

create metrics rating_search_stream as
select
    sum(search_items) as cnt_s_items_with_rating
from rating_search_stream t
;
