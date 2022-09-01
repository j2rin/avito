create fact videocalls_stream as
select
    t.event_date::date as __date__,
    *
from dma.vo_videocalls_stream t
;

create metrics videocalls_stream_user as
select
    sum(case when videocall_contact > 0 then 1 end) as user_videocall_contact,
    sum(case when videocall_iv > 0 then 1 end) as user_videocall_iv
from (
    select
        cookie_id, user_id,
        sum(videocalls_contact) as videocall_contact,
        sum(videocalls_iv) as videocall_iv
    from videocalls_stream t
    group by cookie_id, user_id
) _
;

create metrics videocalls_stream as
select
    sum(videocalls_contact) as videocall_contact,
    sum(videocalls_iv) as videocall_iv
from videocalls_stream t
;
