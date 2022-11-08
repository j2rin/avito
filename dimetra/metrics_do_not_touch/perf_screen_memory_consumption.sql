create fact perf_screen_memory_consumption as
select
    t.event_date::date as __date__,
    *
from dma.perf_screen_memory_consumption t
;

create metrics perf_screen_memory_consumption as
select
    sum(case when metric_name = 'deinited' then 1 end) as screen_deinited_events,
    sum(case when metric_name = 'deinited' then bytes_consumed end) as screen_deinited_memory_consumption_sum,
    sum(case when metric_name = 'presented' then 1 end) as screen_presented_events,
    sum(case when metric_name = 'presented' then bytes_consumed end) as screen_presented_memory_consumption_sum
from perf_screen_memory_consumption t
;
