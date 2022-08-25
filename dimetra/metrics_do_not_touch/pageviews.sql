create fact pageviews as
select
    t.event_date::date as __date__,
    *
from dma.vo_clickstream_pageviews_dimetra t
;

create metrics pageviews as
select
    sum(case when user_id is not null then events_count end) as authorized_page_views,
    sum(itemviews_count) as item_views_count,
    sum(events_count) as page_views
from pageviews t
;

create metrics pageviews_user as
select
    sum(case when authorized_page_views > 0 then 1 end) as daily_active_authorized_users
from (
    select
        cookie_id, user_id,
        sum(case when user_id is not null then events_count end) as authorized_page_views
    from pageviews t
    group by cookie_id, user_id
) _
;

create metrics pageviews_cookie as
select
    sum(case when page_views > 0 then 1 end) as daily_active_users
from (
    select
        cookie_id,
        sum(events_count) as page_views
    from pageviews t
    group by cookie_id
) _
;

create metrics pageviews_cookie_day_hash as
select
    sum(case when item_views_count > 0 then 1 end) as user_day_iv
from (
    select
        cookie_id, cookie_day_hash,
        sum(itemviews_count) as item_views_count
    from pageviews t
    group by cookie_id, cookie_day_hash
) _
;

create metrics pageviews_cookie_month_hash as
select
    sum(case when item_views_count > 0 then 1 end) as user_month_iv
from (
    select
        cookie_id, cookie_month_hash,
        sum(itemviews_count) as item_views_count
    from pageviews t
    group by cookie_id, cookie_month_hash
) _
;
