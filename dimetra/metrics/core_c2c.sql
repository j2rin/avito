create fact core_c2c as
select
    t.event_date as __date__,
    t.cookie_id,
    t.deactivated_listers,
    t.deactivated_listers_changed_segment,
    t.deactivated_listers_involuntary,
    t.deactivated_listers_voluntary,
    t.event_date
from dma.vo_core_c2c t
;

create metrics core_c2c as
select
    sum(deactivated_listers) as deactivated_listers,
    sum(deactivated_listers_changed_segment) as deactivated_listers_changed_segment,
    sum(deactivated_listers_involuntary) as deactivated_listers_involuntary,
    sum(deactivated_listers_voluntary) as deactivated_listers_voluntary
from core_c2c t
;
