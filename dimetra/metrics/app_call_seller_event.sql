create fact app_call_seller_event as
select
    t.event_date as __date__,
    t.appcall_item_add_iac_popup_accepted,
    t.appcall_item_add_iac_popup_show,
    t.appcall_receiver_end_call_rating,
    t.cookie_id,
    t.event_date,
    t.user_id as user
from dma.vo_app_call_seller_event t
;

create metrics app_call_seller_event as
select
    sum(appcall_item_add_iac_popup_accepted) as appcall_item_add_iac_popup_accepted,
    sum(appcall_item_add_iac_popup_show) as appcall_item_add_iac_popup_show,
    sum(case when appcall_receiver_end_call_rating > 0 then 1 end) as appcall_receiver_end_call_feedback_count,
    sum(case when appcall_receiver_end_call_rating > 0 then appcall_receiver_end_call_rating end) as appcall_receiver_end_call_feedback_sum
from app_call_seller_event t
;

create metrics app_call_seller_event_user as
select
    sum(case when appcall_item_add_iac_popup_show > 0 then 1 end) as appcall_item_add_iac_popup_show_users
from (
    select
        cookie_id, user,
        sum(appcall_item_add_iac_popup_show) as appcall_item_add_iac_popup_show
    from app_call_seller_event t
    group by cookie_id, user
) _
;
