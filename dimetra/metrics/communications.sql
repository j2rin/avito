create fact communications as
select
    t.event_date::date as __date__,
    t.anonnumber_calls,
    t.anonnumber_calls_duration,
    t.anonnumber_long_talks,
    t.anonnumber_success_calls,
    t.anonnumber_success_calls_duration,
    t.anonnumber_success_talks,
    t.anonnumber_success_talks_duration,
    t.anonnumber_talks_duration,
    t.anonnumber_usefull_talks,
    t.anonnumber_useless_talks,
    t.event_date,
    t.user_id as user,
    t.user_id
from dma.vo_communications t
;

create metrics communications as
select
    sum(anonnumber_calls) as anonnumber_calls,
    sum(anonnumber_calls_duration) as anonnumber_calls_dur,
    sum(anonnumber_long_talks) as anonnumber_long_talks,
    sum(anonnumber_success_calls) as anonnumber_success_calls,
    sum(anonnumber_success_calls_duration) as anonnumber_success_calls_dur,
    sum(anonnumber_success_talks) as anonnumber_success_talks,
    sum(anonnumber_success_talks_duration) as anonnumber_success_talks_dur,
    sum(anonnumber_talks_duration) as anonnumber_talks_dur,
    sum(anonnumber_usefull_talks) as anonnumber_usefull_talks,
    sum(anonnumber_useless_talks) as anonnumber_useless_talks
from communications t
;

create metrics communications_user as
select
    sum(case when anonnumber_long_talks > 0 then 1 end) as anonnumber_long_talkers,
    sum(case when anonnumber_success_talks > 0 then 1 end) as anonnumber_success_talkers,
    sum(case when anonnumber_success_calls > 0 then 1 end) as anonnumber_success_users,
    sum(case when anonnumber_calls > 0 then 1 end) as anonnumber_users
from (
    select
        user_id, user,
        sum(anonnumber_calls) as anonnumber_calls,
        sum(anonnumber_long_talks) as anonnumber_long_talks,
        sum(anonnumber_success_calls) as anonnumber_success_calls,
        sum(anonnumber_success_talks) as anonnumber_success_talks
    from communications t
    group by user_id, user
) _
;
