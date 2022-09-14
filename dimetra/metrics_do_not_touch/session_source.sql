create fact session_source as
select
    t.event_date::date as __date__,
    *
from dma.vo_session_source t
;

create metrics session_source as
select
    sum(case when observation_name = 'traffic_sessions' then observation_value end) as cnt_traffic_sessions
from session_source t
;

create metrics session_source_cookie as
select
    sum(case when cnt_traffic_sessions > 0 then 1 end) as traffic_sessions
from (
    select
        cookie_id,
        sum(case when observation_name = 'traffic_sessions' then observation_value end) as cnt_traffic_sessions
    from session_source t
    group by cookie_id
) _
;