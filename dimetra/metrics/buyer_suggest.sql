create fact buyer_suggest as
select
    t.event_date as __date__,
    t.cookie_id as cookie,
    t.cookie_id,
    t.event_date,
    t.search_suggest_clicks,
    t.session_searches_with_empty_or_uniq_query,
    t.session_searches_with_uniq_query,
    t.sessions_with_query_suggest_click_contact,
    t.sessions_with_suggest_click_and_contact,
    t.suggest_user_query_len
from dma.vo_buyer_suggest t
;

create metrics buyer_suggest as
select
    sum(session_searches_with_empty_or_uniq_query) as cnt_session_s_with_empty_or_uniq_query,
    sum(session_searches_with_uniq_query) as cnt_session_s_with_uniq_query,
    sum(sessions_with_query_suggest_click_contact) as cnt_sessions_with_query_suggest_click_c,
    sum(sessions_with_suggest_click_and_contact) as cnt_sessions_with_suggest_click_and_c,
    sum(search_suggest_clicks) as suggest_clicks,
    sum(suggest_user_query_len) as suggest_user_query_len
from buyer_suggest t
;

create metrics buyer_suggest_cookie as
select
    sum(case when suggest_clicks > 0 then 1 end) as search_suggest_clicks,
    sum(case when cnt_sessions_with_query_suggest_click_c > 0 then 1 end) as share_suggest_buyers_to_all_users,
    sum(case when cnt_sessions_with_suggest_click_and_c > 0 then 1 end) as suggest_buyers_with_all_queries,
    sum(case when cnt_session_s_with_empty_or_uniq_query > 0 then 1 end) as unq_session_s_with_empty_or_uniq_query,
    sum(case when cnt_session_s_with_uniq_query > 0 then 1 end) as unq_session_s_with_uniq_query
from (
    select
        cookie_id, cookie,
        sum(session_searches_with_empty_or_uniq_query) as cnt_session_s_with_empty_or_uniq_query,
        sum(session_searches_with_uniq_query) as cnt_session_s_with_uniq_query,
        sum(sessions_with_query_suggest_click_contact) as cnt_sessions_with_query_suggest_click_c,
        sum(sessions_with_suggest_click_and_contact) as cnt_sessions_with_suggest_click_and_c,
        sum(search_suggest_clicks) as suggest_clicks
    from buyer_suggest t
    group by cookie_id, cookie
) _
;
