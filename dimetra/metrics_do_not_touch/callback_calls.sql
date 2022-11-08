create fact callback_calls as
select
    t.event_date::date as __date__,
    *
from dma.vo_recallme_calls t
;

create metrics callback_calls as
select
    sum(case when talk_duration_b > 0 then 1 end) as callback_call_answered,
    sum(case when talk_duration_b > 30 then 1 end) as callback_call_success,
    sum(case when talk_duration_a > 0 then 1 end) as callback_call_total
from callback_calls t
;

create metrics callback_calls_cookie as
select
    sum(case when callback_call_answered > 0 then 1 end) as user_callback_call_answered,
    sum(case when callback_call_success > 0 then 1 end) as user_callback_call_success,
    sum(case when callback_call_total > 0 then 1 end) as user_callback_call_total
from (
    select
        cookie_id,
        sum(case when talk_duration_b > 0 then 1 end) as callback_call_answered,
        sum(case when talk_duration_b > 30 then 1 end) as callback_call_success,
        sum(case when talk_duration_a > 0 then 1 end) as callback_call_total
    from callback_calls t
    group by cookie_id
) _
;
