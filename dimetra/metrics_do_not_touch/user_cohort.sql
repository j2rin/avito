create fact user_cohort as
select
    t.event_date::date as __date__,
    *
from dma.vo_user_cohort t
;

create metrics user_cohort as
select
    sum(1) as cnt_new_listers
from user_cohort t
;

create metrics user_cohort_user_logcat as
select
    sum(case when cnt_new_listers > 0 then 1 end) as new_listers
from (
    select
        user_id, logical_category_id,
        sum(1) as cnt_new_listers
    from user_cohort t
    group by user_id, logical_category_id
) _
;
