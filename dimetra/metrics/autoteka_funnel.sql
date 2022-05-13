create fact autoteka_funnel as
select
    t.event_date::date as __date__,
    t.autoteka_cookie_id,
    t.cookie_session,
    t.event_date,
    t.event_type,
    t.is_main_page_session,
    t.is_session_to_exclude
from dma.v_autoteka_funnel_main t
;

create metrics autoteka_funnel as
select
    sum(case when event_type = 'callback' and is_main_page_session = True and is_session_to_exclude = False then cookie_session end) as autoteka_funnel_callback,
    sum(case when event_type = 'main' and is_main_page_session = True and is_session_to_exclude = False then cookie_session end) as autoteka_funnel_main,
    sum(case when event_type = 'paypage' and is_main_page_session = True and is_session_to_exclude = False then cookie_session end) as autoteka_funnel_paypage,
    sum(case when event_type = 'preview' and is_main_page_session = True and is_session_to_exclude = False then cookie_session end) as autoteka_funnel_preview,
    sum(case when event_type = 'selection' and is_main_page_session = True and is_session_to_exclude = False then cookie_session end) as autoteka_funnel_selection,
    sum(cookie_session) as autoteka_sessions
from autoteka_funnel t
;

create metrics autoteka_funnel_cookie_session as
select
    sum(case when autoteka_funnel_callback > 0 then 1 end) as autoteka_funnel_callback_session,
    sum(case when autoteka_funnel_main > 0 then 1 end) as autoteka_funnel_main_session,
    sum(case when autoteka_funnel_paypage > 0 then 1 end) as autoteka_funnel_paypage_session,
    sum(case when autoteka_funnel_preview > 0 then 1 end) as autoteka_funnel_preview_session,
    sum(case when autoteka_funnel_selection > 0 then 1 end) as autoteka_funnel_selection_session,
    sum(case when autoteka_sessions > 0 then 1 end) as autoteka_session_cnt
from (
    select
        autoteka_cookie_id, cookie_session,
        sum(case when event_type = 'callback' and is_main_page_session = True and is_session_to_exclude = False then cookie_session end) as autoteka_funnel_callback,
        sum(case when event_type = 'main' and is_main_page_session = True and is_session_to_exclude = False then cookie_session end) as autoteka_funnel_main,
        sum(case when event_type = 'paypage' and is_main_page_session = True and is_session_to_exclude = False then cookie_session end) as autoteka_funnel_paypage,
        sum(case when event_type = 'preview' and is_main_page_session = True and is_session_to_exclude = False then cookie_session end) as autoteka_funnel_preview,
        sum(case when event_type = 'selection' and is_main_page_session = True and is_session_to_exclude = False then cookie_session end) as autoteka_funnel_selection,
        sum(cookie_session) as autoteka_sessions
    from autoteka_funnel t
    group by autoteka_cookie_id, cookie_session
) _
;
