with cal as
(select *
from
	dict.calendar
where cast(event_date as date) between :first_date and :last_date),
user_address as
(select
    event_date,
    uad.*
from
	cal
    	join dma.current_user_addresses uad on cast(created_at as date)<=event_date
where user_id not in (select user_id from dma."current_user" where isTest)
),
dau as
(select
	event_date, user_id, platform_id, sum(pv_count) pv_count
from
	dma.dau_source
where pv_count>0 and cast(event_date as date) between :first_date and :last_date
group by 1,2,3)
select
    t.event_date,
    t.useraddress_id,
    dau.platform_id,
    t.user_id,
    t.kind,
    t.status,
	t.has_apartments,
    t.has_entrance,
    t.has_floor,
    t.has_comment,
    t.created_at,
    t.updated_at,
    t.deleted_at,
    cast(t.created_at as date) = t.event_date as created_today,
    cast(t.updated_at as date) = t.event_date as updated_today,
    cast(t.deleted_at as date) = t.event_date as deleted_today,
    coalesce(pv_count, 0) as pv_count
from
    user_address t
        left join dau on dau.event_date = t.event_date and dau.user_id = t.user_id
