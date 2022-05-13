create fact perf_mobile_apps_startup_times as
select
    t.event_date::date as __date__,
    t.cookie_id,
    t.event_date,
    t.startup_time_count,
    t.startup_time_sum,
    t.time_to_interact_count,
    t.time_to_interact_sum
from dma.o_perf_mobile_apps_startup_times t
;

create metrics perf_mobile_apps_startup_times as
select
    sum(startup_time_count) as perf_internal_startup_time_count,
    sum(startup_time_sum) as perf_internal_startup_time_sum,
    sum(time_to_interact_count) as perf_internal_time_to_interact_count,
    sum(time_to_interact_sum) as perf_internal_time_to_interact_sum
from perf_mobile_apps_startup_times t
;
