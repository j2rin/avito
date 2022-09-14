create fact clickstream_antibot as
select
    t.event_date::date as __date__,
    *
from dma.o_clickstream_antibot t
;

create metrics clickstream_antibot_cookie as
select
    sum(case when clean_clickstream_events > 0 then 1 end) as clean_clickstream_cookies,
    sum(case when clean_false_positive_events > 0 then 1 end) as clean_false_positive_cookies,
    sum(case when dirty_clickstream_events > 0 then 1 end) as dirty_clickstream_cookies,
    sum(case when dirty_false_positive_events > 0 then 1 end) as dirty_false_positive_cookies
from (
    select
        cookie_id,
        sum(case when is_human = 1 then events end) as clean_clickstream_events,
        sum(case when is_clean_cookie = 1 then events end) as clean_false_positive_events,
        sum(events) as dirty_clickstream_events,
        sum(case when is_clean_cookie = 1 and is_human = 0 then events end) as dirty_false_positive_events
    from clickstream_antibot t
    group by cookie_id
) _
;

create metrics clickstream_antibot as
select
    sum(case when is_human = 1 then events end) as clean_clickstream_events,
    sum(case when is_clean_cookie = 1 then events end) as clean_false_positive_events,
    sum(events) as dirty_clickstream_events,
    sum(case when is_clean_cookie = 1 and is_human = 0 then events end) as dirty_false_positive_events
from clickstream_antibot t
;