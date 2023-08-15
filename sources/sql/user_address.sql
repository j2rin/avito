with cal as 
(select * from dict.calendar where event_date::date between :first_date and :last_date),
user_address as 
(select 
    event_date,
    uad.* 
from 
cal
    join dma.current_user_addresses uad on created_at::date<=event_date
)
select 
    t.event_date,
    t.useraddress_id,
    dau.platform_id,
    t.user_id,
    t.kind,
    t.status,
    t.has_entrance,
    t.has_floor,
    t.has_comment,
    t.created_at,
    t.updated_at,
    t.deleted_at,
    t.created_at::date = t.event_date as created_today,
    t.updated_at::date = t.event_date as updated_today,
    t.deleted_at::date = t.event_date as deleted_today,
    ifnull(pv_count,0) as pv_count
from 
    user_address t
        left join (select event_date, user_id, platform_id, sum(pv_count) pv_count from dma.dau_source where pv_count>0 and event_date::date between :first_date and :last_date group by 1,2,3)dau using(event_date, user_id);
        