create fact target_call_sx as
select
    t.call_time::date as __date__,
    *
from dma.vo_target_call t
;

create metrics target_call_sx as
select
    sum(case when talk_duration > 0 then 1 end) as answered_call_sx,
    sum(case when call_id > 0 then 1 end) as call_sx,
    sum(case when is_target_call = True then 1 end) as target_contact_call_sx,
    sum(case when is_target_call = True and talk_duration > 30 then 1 end) as target_contact_call_sx_success,
    sum(case when is_target_call = True then talk_duration end) as target_contact_call_sx_talkseconds
from target_call_sx t
;

create metrics target_call_sx_user as
select
    sum(case when answered_call_sx > 0 then 1 end) as user_answered_call_sx,
    sum(case when call_sx > 0 then 1 end) as user_call_sx,
    sum(case when target_contact_call_sx > 0 then 1 end) as user_target_contact_call_sx,
    sum(case when target_contact_call_sx_success > 0 then 1 end) as user_target_contact_call_sx_success
from (
    select
        seller_id,
        sum(case when talk_duration > 0 then 1 end) as answered_call_sx,
        sum(case when call_id > 0 then 1 end) as call_sx,
        sum(case when is_target_call = True then 1 end) as target_contact_call_sx,
        sum(case when is_target_call = True and talk_duration > 30 then 1 end) as target_contact_call_sx_success
    from target_call_sx t
    group by seller_id
) _
;
