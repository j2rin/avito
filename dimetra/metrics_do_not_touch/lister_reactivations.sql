create fact lister_reactivations as
select
    t.event_date::date as __date__,
    *
from dma.vo_lister_reactivations t
;

create metrics lister_reactivations as
select
    sum(1) as cnt_reactivated_listers
from lister_reactivations t
;

create metrics lister_reactivations_reactivation_id as
select
    sum(case when cnt_reactivated_listers > 0 then 1 end) as reactivated_listers
from (
    select
        user_id, reactivation_id,
        sum(1) as cnt_reactivated_listers
    from lister_reactivations t
    group by user_id, reactivation_id
) _
;
