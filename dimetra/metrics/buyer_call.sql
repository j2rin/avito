create fact buyer_call as
select
    t.event_date as __date__,
    t.cookie_id,
    t.event_date,
    t.observation_name,
    t.observation_value,
    t.participant_id as participant
from dma.vo_buyer_call t
;

create metrics buyer_call as
select
    sum(case when observation_name = 'anon_calls_matched_answered' then observation_value end) as ancalls_answered_any_type,
    sum(case when observation_name = 'anon_calls_matched_any_type' then observation_value end) as ancalls_any_type,
    sum(case when observation_name = 'anon_calls_matched_any_type_fav' then observation_value end) as ancalls_any_type_fav,
    sum(case when observation_name = 'anon_calls_matched_any_type_map' then observation_value end) as ancalls_any_type_map,
    sum(case when observation_name = 'anon_calls_matched_any_type_rec' then observation_value end) as ancalls_any_type_rec,
    sum(case when observation_name = 'anon_calls_matched_any_type_serp' then observation_value end) as ancalls_any_type_serp,
    sum(case when observation_name = 'anon_calls_matched_both_types' then observation_value end) as ancalls_both_types,
    sum(case when observation_name = 'anon_calls_matched_both_types_fav' then observation_value end) as ancalls_both_types_fav,
    sum(case when observation_name = 'anon_calls_matched_both_types_map' then observation_value end) as ancalls_both_types_map,
    sum(case when observation_name = 'anon_calls_matched_both_types_rec' then observation_value end) as ancalls_both_types_rec,
    sum(case when observation_name = 'anon_calls_matched_both_types_serp' then observation_value end) as ancalls_both_types_serp,
    sum(case when observation_name = 'anon_calls_matched_by_phone' then observation_value end) as ancalls_by_phone,
    sum(case when observation_name = 'anon_calls_matched_by_phone_fav' then observation_value end) as ancalls_by_phone_fav,
    sum(case when observation_name = 'anon_calls_matched_by_phone_map' then observation_value end) as ancalls_by_phone_map,
    sum(case when observation_name = 'anon_calls_matched_by_phone_rec' then observation_value end) as ancalls_by_phone_rec,
    sum(case when observation_name = 'anon_calls_matched_by_phone_serp' then observation_value end) as ancalls_by_phone_serp,
    sum(case when observation_name = 'anon_calls_matched_by_phone_and_user' then observation_value end) as ancalls_by_phone_uid,
    sum(case when observation_name = 'anon_calls_matched_by_phone_and_user_fav' then observation_value end) as ancalls_by_phone_uid_fav,
    sum(case when observation_name = 'anon_calls_matched_by_phone_and_user_map' then observation_value end) as ancalls_by_phone_uid_map,
    sum(case when observation_name = 'anon_calls_matched_by_phone_and_user_rec' then observation_value end) as ancalls_by_phone_uid_rec,
    sum(case when observation_name = 'anon_calls_matched_by_phone_and_user_serp' then observation_value end) as ancalls_by_phone_uid_serp,
    sum(case when observation_name = 'anon_calls_matched_by_time' then observation_value end) as ancalls_by_time,
    sum(case when observation_name = 'anon_calls_matched_by_time_fav' then observation_value end) as ancalls_by_time_fav,
    sum(case when observation_name = 'anon_calls_matched_by_time_map' then observation_value end) as ancalls_by_time_map,
    sum(case when observation_name = 'anon_calls_matched_by_time_rec' then observation_value end) as ancalls_by_time_rec,
    sum(case when observation_name = 'anon_calls_matched_by_time_serp' then observation_value end) as ancalls_by_time_serp,
    sum(case when observation_name = 'anon_calls_matched_success' then observation_value end) as ancalls_success_any_type,
    sum(case when observation_name = 'answered_proxy_calls' then observation_value end) as answered_proxy_calls,
    sum(case when observation_name = 'answered_proxy_calls_fav' then observation_value end) as answered_proxy_calls_fav,
    sum(case when observation_name = 'answered_proxy_calls_map' then observation_value end) as answered_proxy_calls_map,
    sum(case when observation_name = 'answered_proxy_calls_rec' then observation_value end) as answered_proxy_calls_rec,
    sum(case when observation_name = 'answered_proxy_calls_serp' then observation_value end) as answered_proxy_calls_serp,
    sum(case when observation_name in ('answered_proxy_calls', 'call_phone_screen_views_client', 'missed_proxy_calls') then observation_value end) as calls,
    sum(case when observation_name in ('answered_proxy_calls_fav', 'missed_proxy_calls_fav') then observation_value end) as calls_fav,
    sum(case when observation_name in ('answered_proxy_calls_map', 'missed_proxy_calls_map') then observation_value end) as calls_map,
    sum(case when observation_name in ('answered_proxy_calls_rec', 'missed_proxy_calls_rec') then observation_value end) as calls_rec,
    sum(case when observation_name in ('answered_proxy_calls_serp', 'missed_proxy_calls_serp') then observation_value end) as calls_serp,
    sum(case when observation_name = 'missed_proxy_calls' then observation_value end) as missed_proxy_calls,
    sum(case when observation_name = 'missed_proxy_calls_fav' then observation_value end) as missed_proxy_calls_fav,
    sum(case when observation_name = 'missed_proxy_calls_map' then observation_value end) as missed_proxy_calls_map,
    sum(case when observation_name = 'missed_proxy_calls_rec' then observation_value end) as missed_proxy_calls_rec,
    sum(case when observation_name = 'missed_proxy_calls_serp' then observation_value end) as missed_proxy_calls_serp
from buyer_call t
;

create metrics buyer_call_participant as
select
    sum(case when ancalls_any_type > 0 then 1 end) as users_ancalls_any_type,
    sum(case when ancalls_both_types > 0 then 1 end) as users_ancalls_both_types,
    sum(case when ancalls_by_phone > 0 then 1 end) as users_ancalls_by_phone,
    sum(case when ancalls_by_phone_uid > 0 then 1 end) as users_ancalls_by_phone_uid,
    sum(case when ancalls_by_time > 0 then 1 end) as users_ancalls_by_time,
    sum(case when ancalls_success_any_type > 0 then 1 end) as users_ancalls_success_any_type,
    sum(case when calls > 0 then 1 end) as users_phone_calls_client,
    sum(case when calls_fav > 0 then 1 end) as users_phone_calls_client_fav,
    sum(case when calls_map > 0 then 1 end) as users_phone_calls_client_map,
    sum(case when calls_serp > 0 then 1 end) as users_phone_calls_client_serp
from (
    select
        cookie_id, participant,
        sum(case when observation_name = 'anon_calls_matched_any_type' then observation_value end) as ancalls_any_type,
        sum(case when observation_name = 'anon_calls_matched_both_types' then observation_value end) as ancalls_both_types,
        sum(case when observation_name = 'anon_calls_matched_by_phone' then observation_value end) as ancalls_by_phone,
        sum(case when observation_name = 'anon_calls_matched_by_phone_and_user' then observation_value end) as ancalls_by_phone_uid,
        sum(case when observation_name = 'anon_calls_matched_by_time' then observation_value end) as ancalls_by_time,
        sum(case when observation_name = 'anon_calls_matched_success' then observation_value end) as ancalls_success_any_type,
        sum(case when observation_name in ('answered_proxy_calls', 'call_phone_screen_views_client', 'missed_proxy_calls') then observation_value end) as calls,
        sum(case when observation_name in ('answered_proxy_calls_fav', 'missed_proxy_calls_fav') then observation_value end) as calls_fav,
        sum(case when observation_name in ('answered_proxy_calls_map', 'missed_proxy_calls_map') then observation_value end) as calls_map,
        sum(case when observation_name in ('answered_proxy_calls_serp', 'missed_proxy_calls_serp') then observation_value end) as calls_serp
    from buyer_call t
    group by cookie_id, participant
) _
;
