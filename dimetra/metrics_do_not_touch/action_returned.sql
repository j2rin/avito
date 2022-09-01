create fact action_returned as
select
    t.event_date::date as __date__,
    *
from dma.vo_action_returned t
;

create metrics action_returned as
select
    sum(case when action_type = 'user_active' and birthday = 1 then 1 end) as active_new,
    sum(case when action_type = 'user_active' and birthday = 0 then 1 end) as active_old,
    sum(case when action_type = 'item_view' and birthday = 1 then 1 end) as iv_new,
    sum(case when action_type = 'item_view' and birthday = 0 then 1 end) as iv_old,
    sum(case when action_type = 'realty_dev_view' and birthday = 1 then 1 end) as realty_dev_view_new,
    sum(case when action_type = 'realty_dev_view' and birthday = 0 then 1 end) as realty_dev_view_old
from action_returned t
;

create metrics action_returned_cookie as
select
    sum(case when active_new > 0 then 1 end) as user_active_new,
    sum(case when active_old > 0 then 1 end) as user_active_old,
    sum(case when iv_new > 0 then 1 end) as user_iv_new,
    sum(case when iv_old > 0 then 1 end) as user_iv_old,
    sum(case when realty_dev_view_new > 0 then 1 end) as user_realty_dev_view_new,
    sum(case when realty_dev_view_old > 0 then 1 end) as user_realty_dev_view_old
from (
    select
        cookie_id,
        sum(case when action_type = 'user_active' and birthday = 1 then 1 end) as active_new,
        sum(case when action_type = 'user_active' and birthday = 0 then 1 end) as active_old,
        sum(case when action_type = 'item_view' and birthday = 1 then 1 end) as iv_new,
        sum(case when action_type = 'item_view' and birthday = 0 then 1 end) as iv_old,
        sum(case when action_type = 'realty_dev_view' and birthday = 1 then 1 end) as realty_dev_view_new,
        sum(case when action_type = 'realty_dev_view' and birthday = 0 then 1 end) as realty_dev_view_old
    from action_returned t
    group by cookie_id
) _
;
