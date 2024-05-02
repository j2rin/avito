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
	event_date,
	user_id,
	platform_id,
	infmquery_id,
	location_id,
	sum(pv_count) pv_count,
	sum(iv_count) iv_count,
	sum(serp_count) serp_count,
	sum(btc_count) btc_count,
	sum(contact) contacts
from
	dma.dau_source
where pv_count>0 and cast(event_date as date) between :first_date and :last_date
group by 1,2,3,4,5),
current_infmquery_category as (
    select infmquery_id, logcat_id, microcat_id
    from infomodel.current_infmquery_category
    where infmquery_id in (
        select distinct infmquery_id
        from dma.dau_source
        where cast(event_date as date) between :first_date and :last_date
            and infmquery_id is not null
    )
)
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
    ic.microcat_id,
    dau.location_id,
    lc.vertical_id,
    lc.logical_category_id,
    lc.logical_param1_id,
    lc.logical_param2_id,
    cm.category_id,
    cm.subcategory_id,
    cm.Param1_microcat_id as param1_id,
    cm.Param2_microcat_id as param2_id,
    cm.Param3_microcat_id as param3_id,
    cm.Param4_microcat_id as param4_id,
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
    cl.LocationGroup_id                                    as location_group_id,
    cl.City_Population_Group                               as population_group,
    cl.Logical_Level                                       as location_level_id,
    coalesce(pv_count, 0) as pv_count,
		coalesce(iv_count, 0) as iv_count,
		coalesce(serp_count, 0) as serp_count,
		coalesce(btc_count, 0) as btc_count,
    coalesce(contacts, 0) as contacts
from
    user_address t
        left join dau on dau.event_date = t.event_date and dau.user_id = t.user_id
        left join /*+jtype(h),distrib(l,a)*/ current_infmquery_category ic on ic.infmquery_id = dau.infmquery_id
        left join /*+jtype(h),distrib(l,a)*/ dma.current_logical_categories lc  on lc.logcat_id = ic.logcat_id
        left join  /*+jtype(h),distrib(l,a)*/dma.current_microcategories cm   on cm.microcat_id = ic.microcat_id
        left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations cl   on cl.Location_id = dau.location_id
