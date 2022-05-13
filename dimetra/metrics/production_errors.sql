create fact production_errors as
select
    t.event_date::date as __date__,
    t.cookie_id as cookie,
    t.cookie_id,
    t.eid,
    t.error_type,
    t.event_date
from dma.vo_production_errors t
;

create metrics production_errors as
select
    sum(case when eid = 3456 then 1 end) as fatal_app_errors,
    sum(case when error_type = 'not found' then 1 end) as not_found_errors
from production_errors t
;

create metrics production_errors_cookie as
select
    sum(case when not_found_errors > 0 then 1 end) as user_not_found_errors,
    sum(case when fatal_app_errors > 0 then 1 end) as users_fatal_app_errors
from (
    select
        cookie_id, cookie,
        sum(case when eid = 3456 then 1 end) as fatal_app_errors,
        sum(case when error_type = 'not found' then 1 end) as not_found_errors
    from production_errors t
    group by cookie_id, cookie
) _
;
