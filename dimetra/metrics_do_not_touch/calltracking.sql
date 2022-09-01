create fact calltracking as
select
    t.event_date::date as __date__,
    *
from dma.vo_calltracking t
;

create metrics calltracking as
select
    sum(calltracking_active) as calltracking_active,
    sum(calls_total) as calltracking_calls,
    sum(fraud_calls) as calltracking_fraud_calls,
    sum(not_fraud_calls) as calltracking_not_fraud_calls,
    sum(case when is_item_cpa = True then not_fraud_calls end) as calltracking_not_fraud_calls_cpa_items,
    sum(case when is_user_cpa = True then not_fraud_calls end) as calltracking_not_fraud_calls_cpa_users,
    sum(received_calls) as calltracking_received_calls,
    sum(case when is_item_cpa = True then received_calls end) as calltracking_received_calls_cpa_items,
    sum(case when is_user_cpa = True then received_calls end) as calltracking_received_calls_cpa_users
from calltracking t
;

create metrics calltracking_user as
select
    sum(case when calltracking_active > 0 then 1 end) as users_calltracking_active,
    sum(case when calltracking_calls > 0 then 1 end) as users_calltracking_calls,
    sum(case when calltracking_fraud_calls > 0 then 1 end) as users_calltracking_fraud_calls,
    sum(case when calltracking_not_fraud_calls > 0 then 1 end) as users_calltracking_not_fraud_calls,
    sum(case when calltracking_not_fraud_calls_cpa_items > 0 then 1 end) as users_calltracking_not_fraud_calls_cpa_items,
    sum(case when calltracking_not_fraud_calls_cpa_users > 0 then 1 end) as users_calltracking_not_fraud_calls_cpa_users,
    sum(case when calltracking_received_calls > 0 then 1 end) as users_calltracking_received_calls,
    sum(case when calltracking_received_calls_cpa_items > 0 then 1 end) as users_calltracking_received_calls_cpa_items,
    sum(case when calltracking_received_calls_cpa_users > 0 then 1 end) as users_calltracking_received_calls_cpa_users
from (
    select
        user_id,
        sum(calltracking_active) as calltracking_active,
        sum(calls_total) as calltracking_calls,
        sum(fraud_calls) as calltracking_fraud_calls,
        sum(not_fraud_calls) as calltracking_not_fraud_calls,
        sum(case when is_item_cpa = True then not_fraud_calls end) as calltracking_not_fraud_calls_cpa_items,
        sum(case when is_user_cpa = True then not_fraud_calls end) as calltracking_not_fraud_calls_cpa_users,
        sum(received_calls) as calltracking_received_calls,
        sum(case when is_item_cpa = True then received_calls end) as calltracking_received_calls_cpa_items,
        sum(case when is_user_cpa = True then received_calls end) as calltracking_received_calls_cpa_users
    from calltracking t
    group by user_id
) _
;
