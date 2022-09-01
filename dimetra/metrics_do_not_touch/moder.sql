create fact moder as
select
    t.event_date::date as __date__,
    *
from dma.vo_moder t
;

create metrics moder as
select
    sum(agent_items_day) as agent_items_day,
    sum(agent_line_time_h) as agent_line_time_h,
    sum(case when backlog_hours < 48 then backlog_hours end) as backlog_hours,
    sum(case when backlog_hours is not null and backlog_hours < 48 then 1 end) as backlog_items,
    sum(items_processed) as items_processed,
    sum(items_processed_before_ttl) as items_processed_before_ttl
from moder t
;
