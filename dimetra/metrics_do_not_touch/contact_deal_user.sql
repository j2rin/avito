create fact contact_deal_user as
select
    t.event_date::date as __date__,
    *
from dma.vo_contact_deal t
;

create metrics contact_deal_user as
select
    sum(case when observation_name in ('anon_calls_matched_any_type', 'answered_first_messages', 'answered_proxy_calls', 'appcall_bx_outgoing_item', 'call_phone_screen_views_client', 'delivery_contact', 'missed_proxy_calls') then observation_value end) as cnt_contact_deal,
    sum(case when observation_name in ('anon_calls_matched_answered', 'anon_calls_matched_any_type', 'answered_first_messages', 'answered_proxy_calls', 'appcall_bx_outgoing_item', 'delivery_contact') then observation_value end) as cnt_contact_deal_answered,
    sum(case when observation_name = 'delivery_contact' then observation_value end) as cnt_contact_deal_delivery
from contact_deal_user t
;

create metrics contact_deal_user_user as
select
    sum(case when cnt_contact_deal_answered > 0 then 1 end) as user_contact_deal_answered_auth,
    sum(case when cnt_contact_deal > 0 then 1 end) as user_contact_deal_auth,
    sum(case when cnt_contact_deal_delivery > 0 then 1 end) as user_contact_deal_delivery_auth
from (
    select
        user_id,
        sum(case when observation_name in ('anon_calls_matched_any_type', 'answered_first_messages', 'answered_proxy_calls', 'appcall_bx_outgoing_item', 'call_phone_screen_views_client', 'delivery_contact', 'missed_proxy_calls') then observation_value end) as cnt_contact_deal,
        sum(case when observation_name in ('anon_calls_matched_answered', 'anon_calls_matched_any_type', 'answered_first_messages', 'answered_proxy_calls', 'appcall_bx_outgoing_item', 'delivery_contact') then observation_value end) as cnt_contact_deal_answered,
        sum(case when observation_name = 'delivery_contact' then observation_value end) as cnt_contact_deal_delivery
    from contact_deal_user t
    group by user_id
) _
;
