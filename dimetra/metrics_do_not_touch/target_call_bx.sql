create fact target_call_bx as
select
    t.call_time::date as __date__,
    *
from dma.vo_target_call t
;

create metrics target_call_bx as
select
    sum(case when talk_duration > 0 then 1 end) as answered_call_bx,
    sum(case when call_id > 0 then 1 end) as call_bx,
    sum(case when is_target_call = True then 1 end) as target_contact_call_bx,
    sum(case when is_target_call = True and talk_duration > 30 then 1 end) as target_contact_call_bx_success,
    sum(case when is_target_call = True then talk_duration end) as target_contact_call_bx_talkseconds
from target_call_bx t
;

create metrics target_call_bx_user as
select
    sum(case when answered_call_bx > 0 then 1 end) as user_answered_call_bx,
    sum(case when call_bx > 0 then 1 end) as user_call_bx,
    sum(case when target_contact_call_bx > 0 then 1 end) as user_target_contact_call_bx,
    sum(case when target_contact_call_bx_success > 0 then 1 end) as user_target_contact_call_bx_success
from (
    select
        buyer_id,
        sum(case when talk_duration > 0 then 1 end) as answered_call_bx,
        sum(case when call_id > 0 then 1 end) as call_bx,
        sum(case when is_target_call = True then 1 end) as target_contact_call_bx,
        sum(case when is_target_call = True and talk_duration > 30 then 1 end) as target_contact_call_bx_success
    from target_call_bx t
    group by buyer_id
) _
;
