select /*+syntactic_join*/
    tnu.item_id,
    tnu.event_date,
    tnu.platform_id,
    tnu.lnd_session_source_full_id as traffic_source_id,
    tnu.event_timestamp as action_dttm,
    tnu.microcat_id,
    tnu.cookie_id,
    lc.vertical_id,
    lc.logical_category_id,
    cm.category_id,
    cm.subcategory_id,
    lc.logical_category,
    cm.param1_microcat_id as param1_id,
    tnu.location_id,
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
    cl.LocationGroup_id                                         as location_group_id,
    cl.City_Population_Group                                    as population_group,
    cl.Logical_Level                                            as location_level_id,
    tnu.user_id,
    lc.logical_param1_id,
    lc.logical_param2_id
from dma.true_new_users tnu
left join /*+jtype(h),distrib(l,a)*/ dma.current_microcategories cm
    on tnu.microcat_id = cm.microcat_id
left join /*+jtype(h),distrib(l,a)*/ dma.current_locations cl
    ON  tnu.location_id = cl.location_id
left join /*+jtype(h),distrib(l,a)*/ (
    select infmquery_id, logcat_id
    from infomodel.current_infmquery_category
    where infmquery_id in (
        select distinct infmquery_id
        from dma.true_new_users
        where event_date between :first_date and :last_date
            and infmquery_id is not null
	-- 		and event_year between date_trunc('year', date(:first_date)) and date_trunc('year', date(:last_date)) -- @trino
    )
) ic
    on tnu.infmquery_id = ic.infmquery_id
left join /*+jtype(h),distrib(l,a)*/ dma.current_logical_categories lc
    on ic.logcat_id = lc.logcat_id
left join /*+jtype(h),distrib(l,a)*/ dict.segmentation_ranks ls
    on   ls.logical_category_id = lc.logical_category_id
    and  ls.is_default
where tnu.event_date between :first_date and :last_date
	-- and tnu.event_year between date_trunc('year', date(:first_date)) and date_trunc('year', date(:last_date)) -- @trino
    
