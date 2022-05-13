create fact user_cohort as
select
    t.event_date::date as __date__,
    t.event_date,
    t.user_id,
    hash(t.user_id, t.logical_category_id) as user_logcat
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
        user_id, user_logcat,
        sum(1) as cnt_new_listers
    from user_cohort t
    group by user_id, user_logcat
) _
;
