create fact pageviews as
select
    t.event_date as __date__,
    t.cookie_id as cookie,
    t.cookie_id,
    t.event_date,
    t.events_count,
    t.user_id as user,
    t.user_id
from dma.vo_clickstream_pageviews t
;

create metrics pageviews as
select
    sum(case when user_id is not null then events_count end) as authorized_page_views,
    sum(events_count) as page_views
from pageviews t
;

create metrics pageviews_user as
select
    sum(case when authorized_page_views > 0 then 1 end) as daily_active_authorized_users
from (
    select
        cookie_id, user,
        sum(case when user_id is not null then events_count end) as authorized_page_views
    from pageviews t
    group by cookie_id, user
) _
;

create metrics pageviews_cookie as
select
    sum(case when page_views > 0 then 1 end) as daily_active_users
from (
    select
        cookie_id, cookie,
        sum(events_count) as page_views
    from pageviews t
    group by cookie_id, cookie
) _
;
