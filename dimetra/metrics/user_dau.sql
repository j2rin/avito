create fact user_dau as
select
    t.event_date::date as __date__,
    t.event_date,
    t.events_count,
    t.user_id as user,
    t.user_id
from dma.vo_clickstream_pageviews t
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
        user_id, user,
        sum(case when user_id is not null then events_count end) as authorized_users_page_views
    from user_dau t
    group by user_id, user
) _
;
