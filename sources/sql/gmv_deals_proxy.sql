select
     dp.event_date
    ,dp.user_id
    ,lc.vertical_id
    ,lc.logical_category_id
    ,decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id) as region_id
	,decode(cl.level, 3, cl.Location_id, null) as city_id
	,cm.category_id
	,cm.subcategory_id
	,nvl(acd.is_asd, False) as is_asd
    ,acd.user_group_id      as asd_user_group_id
    ,dp.user_segment_market
    ,dp.proxy_deals as proxy_deals
    ,dp.gmv_volume as gmv_volume
from dma.gmv_deals_proxy dp
join dma.current_item ci on dp.item_id = ci.item_id
left join dma.current_locations cl on ci.location_id = cl.location_id
left join dma.current_logical_categories lc on dp.logical_category_id = lc.logcat_id
left join dma.current_microcategories cm on dp.microcat_id = cm.microcat_id

left join (
    select
        user_id,
        active_from_date,
        active_to_date,
        (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
        user_group_id
    from DMA.am_client_day_versioned
    where active_from_date <= :last_date
        and active_to_date >= :first_date
) acd
    on   acd.user_id = dp.user_id
    and  dp.event_date between acd.active_from_date and acd.active_to_date

where event_date::date between :first_date and :last_date
