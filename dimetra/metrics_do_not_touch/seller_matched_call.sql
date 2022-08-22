create fact seller_matched_call as
select
    t.event_date::date as __date__,
    *
from dma.vo_seller_matched_call t
;

create metrics seller_matched_call_item as
select
    sum(case when seller_proxy_calls_cpa_items > 0 then 1 end) as item_cpa_uniq_proxy_calls
from (
    select
        user_id, item_id,
        sum(case when is_item_cpa = True and (observation_name in ('answered_proxy_calls', 'call_phone_screen_views_client', 'missed_proxy_calls')) then observation_value end) as seller_proxy_calls_cpa_items
    from seller_matched_call t
    group by user_id, item_id
) _
;

create metrics seller_matched_call as
select
    sum(case when observation_name = 'answered_proxy_calls' then observation_value end) as seller_answered_proxy_calls,
    sum(case when observation_name = 'answered_proxy_calls' and is_item_cpa = True then observation_value end) as seller_answered_proxy_calls_cpa_items,
    sum(case when observation_name = 'answered_proxy_calls' and is_user_cpa = True then observation_value end) as seller_answered_proxy_calls_cpa_users,
    sum(case when observation_name = 'anon_calls_matched_answered' then observation_value end) as seller_matched_ancalls_answered_any_type,
    sum(case when observation_name = 'anon_calls_matched_any_type' then observation_value end) as seller_matched_ancalls_any_type,
    sum(case when observation_name = 'anon_calls_matched_both_types' then observation_value end) as seller_matched_ancalls_both_types,
    sum(case when observation_name = 'anon_calls_matched_by_phone' then observation_value end) as seller_matched_ancalls_by_phone,
    sum(case when observation_name = 'anon_calls_matched_by_time' then observation_value end) as seller_matched_ancalls_by_time,
    sum(case when observation_name = 'anon_calls_matched_success' then observation_value end) as seller_matched_ancalls_success_any_type,
    sum(case when observation_name = 'missed_proxy_calls' then observation_value end) as seller_missed_proxy_calls,
    sum(case when observation_name = 'missed_proxy_calls' and is_item_cpa = True then observation_value end) as seller_missed_proxy_calls_cpa_items,
    sum(case when observation_name = 'missed_proxy_calls' and is_user_cpa = True then observation_value end) as seller_missed_proxy_calls_cpa_users,
    sum(case when observation_name in ('answered_proxy_calls', 'call_phone_screen_views_client', 'missed_proxy_calls') then observation_value end) as seller_proxy_calls,
    sum(case when is_item_cpa = True and (observation_name in ('answered_proxy_calls', 'call_phone_screen_views_client', 'missed_proxy_calls')) then observation_value end) as seller_proxy_calls_cpa_items,
    sum(case when is_user_cpa = True and (observation_name in ('answered_proxy_calls', 'call_phone_screen_views_client', 'missed_proxy_calls')) then observation_value end) as seller_proxy_calls_cpa_users
from seller_matched_call t
;

create metrics seller_matched_call_user as
select
    sum(case when seller_proxy_calls_cpa_users > 0 then 1 end) as seller_cpa_uniq_proxy_calls
from (
    select
        user_id,
        sum(case when is_user_cpa = True and (observation_name in ('answered_proxy_calls', 'call_phone_screen_views_client', 'missed_proxy_calls')) then observation_value end) as seller_proxy_calls_cpa_users
    from seller_matched_call t
    group by user_id
) _
;
