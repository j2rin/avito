create fact pageviews as
select
    t.event_date::date as __date__,
    *
from dma.vo_clickstream_pageviews_dimetra t
participant_columns(cookie_id)
;
