create fact labor as
select
    t.event_date::date as __date__,
    *
from dma.vo_labor t
;

create metrics labor as
select
    sum(case when observation_name = 'ad_pages_to_contact' then observation_value end) as cnt_ad_pages_to_c,
    sum(case when observation_name = 'correct_and_map_searches_and_iv_to_contact' then observation_value end) as cnt_correct_and_map_s_iv_to_c,
    sum(case when observation_name = 'correct_searches_and_iv_to_contact' then observation_value end) as cnt_correct_s_and_iv_to_c,
    sum(case when observation_name = 'correct_searches_to_contact' then observation_value end) as cnt_correct_s_to_c,
    sum(case when observation_name = 'from_session_start_to_c_any_source_p25' then observation_value end) as cnt_from_session_start_to_c_any_source_p25,
    sum(case when observation_name = 'from_session_start_to_c_any_source_p50' then observation_value end) as cnt_from_session_start_to_c_any_source_p50,
    sum(case when observation_name = 'from_session_start_to_c_any_source_p75' then observation_value end) as cnt_from_session_start_to_c_any_source_p75,
    sum(case when observation_name = 'from_session_start_to_c_any_source_p99' then observation_value end) as cnt_from_session_start_to_c_any_source_p99,
    sum(case when observation_name = 'from_session_start_to_c_p25' then observation_value end) as cnt_from_session_start_to_c_p25,
    sum(case when observation_name = 'from_session_start_to_c_p50' then observation_value end) as cnt_from_session_start_to_c_p50,
    sum(case when observation_name = 'from_session_start_to_c_p75' then observation_value end) as cnt_from_session_start_to_c_p75,
    sum(case when observation_name = 'from_session_start_to_c_p99' then observation_value end) as cnt_from_session_start_to_c_p99,
    sum(case when observation_name = 'from_session_start_to_iv_any_source_p25' then observation_value end) as cnt_from_session_start_to_iv_any_source_p25,
    sum(case when observation_name = 'from_session_start_to_iv_any_source_p50' then observation_value end) as cnt_from_session_start_to_iv_any_source_p50,
    sum(case when observation_name = 'from_session_start_to_iv_any_source_p75' then observation_value end) as cnt_from_session_start_to_iv_any_source_p75,
    sum(case when observation_name = 'from_session_start_to_iv_any_source_p99' then observation_value end) as cnt_from_session_start_to_iv_any_source_p99,
    sum(case when observation_name = 'from_session_start_to_iv_p25' then observation_value end) as cnt_from_session_start_to_iv_p25,
    sum(case when observation_name = 'from_session_start_to_iv_p50' then observation_value end) as cnt_from_session_start_to_iv_p50,
    sum(case when observation_name = 'from_session_start_to_iv_p75' then observation_value end) as cnt_from_session_start_to_iv_p75,
    sum(case when observation_name = 'from_session_start_to_iv_p99' then observation_value end) as cnt_from_session_start_to_iv_p99,
    sum(case when observation_name = 'item_views_to_contact' then observation_value end) as cnt_iv_to_c,
    sum(case when observation_name = 'map_searches_and_iv_to_contact' then observation_value end) as cnt_map_s_and_iv_to_c,
    sum(case when observation_name = 'map_searches_to_contact' then observation_value end) as cnt_map_s_to_c,
    sum(case when observation_name = 'searches_and_iv_to_contact' then observation_value end) as cnt_s_and_iv_to_c,
    sum(case when observation_name = 'searches_to_contact' then observation_value end) as cnt_s_to_c,
    sum(case when observation_name = 'from_session_start_to_c' then observation_value end) as from_session_start_to_c,
    sum(case when observation_name = 'from_session_start_to_c_any_source' then observation_value end) as from_session_start_to_c_any_source,
    sum(case when observation_name = 'from_session_start_to_c_map' then observation_value end) as from_session_start_to_c_map,
    sum(case when observation_name = 'from_session_start_to_c_search_nq' then observation_value end) as from_session_start_to_c_search_nq,
    sum(case when observation_name = 'from_session_start_to_iv' then observation_value end) as from_session_start_to_iv,
    sum(case when observation_name = 'from_session_start_to_iv_any_source' then observation_value end) as from_session_start_to_iv_any_source,
    sum(case when observation_name = 'from_session_start_to_iv_map' then observation_value end) as from_session_start_to_iv_map,
    sum(case when observation_name = 'from_session_start_to_iv_search_nq' then observation_value end) as from_session_start_to_iv_search_nq
from labor t
;

create metrics labor_session as
select
    sum(case when from_session_start_to_c > 0 then 1 end) as unq_session_from_session_start_to_c,
    sum(case when from_session_start_to_iv > 0 then 1 end) as unq_session_from_session_start_to_iv
from (
    select
        cookie_id, session_no,
        sum(case when observation_name = 'from_session_start_to_c' then observation_value end) as from_session_start_to_c,
        sum(case when observation_name = 'from_session_start_to_iv' then observation_value end) as from_session_start_to_iv
    from labor t
    group by cookie_id, session_no
) _
;

create metrics labor_participant as
select
    sum(case when cnt_from_session_start_to_c_any_source_p25 > 0 then 1 end) as user_from_session_start_to_c_any_source_p25,
    sum(case when cnt_from_session_start_to_c_any_source_p50 > 0 then 1 end) as user_from_session_start_to_c_any_source_p50,
    sum(case when cnt_from_session_start_to_c_any_source_p75 > 0 then 1 end) as user_from_session_start_to_c_any_source_p75,
    sum(case when cnt_from_session_start_to_c_any_source_p99 > 0 then 1 end) as user_from_session_start_to_c_any_source_p99,
    sum(case when cnt_from_session_start_to_c_p25 > 0 then 1 end) as user_from_session_start_to_c_p25,
    sum(case when cnt_from_session_start_to_c_p50 > 0 then 1 end) as user_from_session_start_to_c_p50,
    sum(case when cnt_from_session_start_to_c_p75 > 0 then 1 end) as user_from_session_start_to_c_p75,
    sum(case when cnt_from_session_start_to_c_p99 > 0 then 1 end) as user_from_session_start_to_c_p99,
    sum(case when cnt_from_session_start_to_iv_any_source_p25 > 0 then 1 end) as user_from_session_start_to_iv_any_source_p25,
    sum(case when cnt_from_session_start_to_iv_any_source_p50 > 0 then 1 end) as user_from_session_start_to_iv_any_source_p50,
    sum(case when cnt_from_session_start_to_iv_any_source_p75 > 0 then 1 end) as user_from_session_start_to_iv_any_source_p75,
    sum(case when cnt_from_session_start_to_iv_any_source_p99 > 0 then 1 end) as user_from_session_start_to_iv_any_source_p99,
    sum(case when cnt_from_session_start_to_iv_p25 > 0 then 1 end) as user_from_session_start_to_iv_p25,
    sum(case when cnt_from_session_start_to_iv_p50 > 0 then 1 end) as user_from_session_start_to_iv_p50,
    sum(case when cnt_from_session_start_to_iv_p75 > 0 then 1 end) as user_from_session_start_to_iv_p75,
    sum(case when cnt_from_session_start_to_iv_p99 > 0 then 1 end) as user_from_session_start_to_iv_p99
from (
    select
        cookie_id, participant_id,
        sum(case when observation_name = 'from_session_start_to_c_any_source_p25' then observation_value end) as cnt_from_session_start_to_c_any_source_p25,
        sum(case when observation_name = 'from_session_start_to_c_any_source_p50' then observation_value end) as cnt_from_session_start_to_c_any_source_p50,
        sum(case when observation_name = 'from_session_start_to_c_any_source_p75' then observation_value end) as cnt_from_session_start_to_c_any_source_p75,
        sum(case when observation_name = 'from_session_start_to_c_any_source_p99' then observation_value end) as cnt_from_session_start_to_c_any_source_p99,
        sum(case when observation_name = 'from_session_start_to_c_p25' then observation_value end) as cnt_from_session_start_to_c_p25,
        sum(case when observation_name = 'from_session_start_to_c_p50' then observation_value end) as cnt_from_session_start_to_c_p50,
        sum(case when observation_name = 'from_session_start_to_c_p75' then observation_value end) as cnt_from_session_start_to_c_p75,
        sum(case when observation_name = 'from_session_start_to_c_p99' then observation_value end) as cnt_from_session_start_to_c_p99,
        sum(case when observation_name = 'from_session_start_to_iv_any_source_p25' then observation_value end) as cnt_from_session_start_to_iv_any_source_p25,
        sum(case when observation_name = 'from_session_start_to_iv_any_source_p50' then observation_value end) as cnt_from_session_start_to_iv_any_source_p50,
        sum(case when observation_name = 'from_session_start_to_iv_any_source_p75' then observation_value end) as cnt_from_session_start_to_iv_any_source_p75,
        sum(case when observation_name = 'from_session_start_to_iv_any_source_p99' then observation_value end) as cnt_from_session_start_to_iv_any_source_p99,
        sum(case when observation_name = 'from_session_start_to_iv_p25' then observation_value end) as cnt_from_session_start_to_iv_p25,
        sum(case when observation_name = 'from_session_start_to_iv_p50' then observation_value end) as cnt_from_session_start_to_iv_p50,
        sum(case when observation_name = 'from_session_start_to_iv_p75' then observation_value end) as cnt_from_session_start_to_iv_p75,
        sum(case when observation_name = 'from_session_start_to_iv_p99' then observation_value end) as cnt_from_session_start_to_iv_p99
    from labor t
    group by cookie_id, participant_id
) _
;
