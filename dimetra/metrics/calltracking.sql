create fact calltracking as
select
    t.calls_total,
    t.calltracking_active,
    t.event_date,
    t.fraud_calls,
    t.not_fraud_calls,
    t.received_calls,
    t.user_id as user,
    t.user_id
from dma.vo_calltracking t
;

create metrics calltracking as
select
    sum(calltracking_active) as calltracking_active,
    sum(calls_total) as calltracking_calls,
    sum(fraud_calls) as calltracking_fraud_calls,
    sum(not_fraud_calls) as calltracking_not_fraud_calls,
    sum(received_calls) as calltracking_received_calls
from calltracking t
;

create metrics calltracking_user as
select
    sum(case when calltracking_active > 0 then 1 end) as users_calltracking_active,
    sum(case when calltracking_calls > 0 then 1 end) as users_calltracking_calls,
    sum(case when calltracking_fraud_calls > 0 then 1 end) as users_calltracking_fraud_calls,
    sum(case when calltracking_not_fraud_calls > 0 then 1 end) as users_calltracking_not_fraud_calls,
    sum(case when calltracking_received_calls > 0 then 1 end) as users_calltracking_received_calls
from (
    select
        user_id, user,
        sum(calltracking_active) as calltracking_active,
        sum(calls_total) as calltracking_calls,
        sum(fraud_calls) as calltracking_fraud_calls,
        sum(not_fraud_calls) as calltracking_not_fraud_calls,
        sum(received_calls) as calltracking_received_calls
    from calltracking t
    group by user_id, user
) _
;
