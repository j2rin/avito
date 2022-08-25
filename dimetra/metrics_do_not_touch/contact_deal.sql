create fact contact_deal as
select
    t.event_date::date as __date__,
    *
from dma.vo_contact_deal t
;

create metrics contact_deal as
select
    sum(case when observation_name in ('anon_calls_matched_any_type', 'answered_first_messages', 'answered_proxy_calls', 'appcall_bx_outgoing_item', 'call_phone_screen_views_client', 'delivery_contact', 'missed_proxy_calls') then observation_value end) as contact_deal,
    sum(case when observation_name in ('anon_calls_matched_answered', 'answered_first_messages', 'answered_proxy_calls', 'appcall_bx_outgoing_item', 'delivery_contact') then observation_value end) as contact_deal_answered
from contact_deal t
;

create metrics contact_deal_cookie as
select
    sum(case when contact_deal > 0 then 1 end) as user_contact_deal,
    sum(case when contact_deal_answered > 0 then 1 end) as user_contact_deal_answered
from (
    select
        cookie_id,
        sum(case when observation_name in ('anon_calls_matched_any_type', 'answered_first_messages', 'answered_proxy_calls', 'appcall_bx_outgoing_item', 'call_phone_screen_views_client', 'delivery_contact', 'missed_proxy_calls') then observation_value end) as contact_deal,
        sum(case when observation_name in ('anon_calls_matched_answered', 'answered_first_messages', 'answered_proxy_calls', 'appcall_bx_outgoing_item', 'delivery_contact') then observation_value end) as contact_deal_answered
    from contact_deal t
    group by cookie_id
) _
;
