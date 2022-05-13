create fact callcenter_calls as
select
    t.enter_date::date as __date__,
    t.call_answered,
    t.enter_date,
    t.feedbackmark,
    t.sec_to_reply,
    t.user_id
from dma.vo_callcenter_calls t
;

create metrics callcenter_calls as
select
    sum(1) as callcenter_calls_big10,
    sum(call_answered) as calls_answered,
    sum(sec_to_reply) as calls_sec_to_reply,
    sum(case when feedbackmark >= 4 then 1 end) as high_scored_calls,
    sum(case when feedbackmark = 1 then 1 end) as low_scored_calls,
    sum(case when feedbackmark is not null then 1 end) as scored_calls
from callcenter_calls t
;
