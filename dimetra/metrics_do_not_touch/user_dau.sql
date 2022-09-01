create fact user_dau as
select
    t.event_date::date as __date__,
    *
from dma.vo_clickstream_pageviews_dimetra t
;

create metrics user_dau as
select
    sum(case when user_id is not null then events_count end) as authorized_users_page_views
from user_dau t
;

create metrics user_dau_user as
select
    sum(case when authorized_users_page_views > 0 then 1 end) as daily_active_uniq_authorized_users
from (
    select
        user_id,
        sum(case when user_id is not null then events_count end) as authorized_users_page_views
    from user_dau t
    group by user_id
) _
;
