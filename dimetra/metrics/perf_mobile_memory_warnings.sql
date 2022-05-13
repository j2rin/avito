create fact perf_mobile_memory_warnings as
select
    t.event_date as __date__,
    t.app_state,
    t.cookie_id as cookie,
    t.cookie_id,
    t.event_date,
    t.events
from dma.o_perf_memory_warnings t
;

create metrics perf_mobile_memory_warnings as
select
    sum(case when app_state = 'active' then events end) as active_memory_warnings_count,
    sum(case when app_state = 'background' then events end) as background_memory_warnings_count,
    sum(case when app_state = 'inactive' then events end) as inactive_memory_warnings_count,
    sum(events) as total_memory_warnings_count,
    sum(case when app_state = 'unknown' then events end) as unknown_memory_warnings_count
from perf_mobile_memory_warnings t
;

create metrics perf_mobile_memory_warnings_cookie as
select
    sum(case when active_memory_warnings_count > 0 then 1 end) as active_memory_warnings_users,
    sum(case when background_memory_warnings_count > 0 then 1 end) as background_memory_warnings_users,
    sum(case when inactive_memory_warnings_count > 0 then 1 end) as inactive_memory_warnings_users,
    sum(case when total_memory_warnings_count > 0 then 1 end) as total_memory_warnings_users,
    sum(case when unknown_memory_warnings_count > 0 then 1 end) as unknown_memory_warnings_users
from (
    select
        cookie_id, cookie,
        sum(case when app_state = 'active' then events end) as active_memory_warnings_count,
        sum(case when app_state = 'background' then events end) as background_memory_warnings_count,
        sum(case when app_state = 'inactive' then events end) as inactive_memory_warnings_count,
        sum(events) as total_memory_warnings_count,
        sum(case when app_state = 'unknown' then events end) as unknown_memory_warnings_count
    from perf_mobile_memory_warnings t
    group by cookie_id, cookie
) _
;
