select c.event_date
    , c.user_id
    , c.infmquery_id
    , c.location_id
    , is_received
    , is_callback
    , cpaaction_id_is_known
    , item_is_knowm
    , is_target
    , is_protested
    , rejected_repeated
    , rejected_not_target
    , rejected_no_price
    , rejected_non_cpa_item
    , rejected_removed_content
    , rejected_non_working_hours
    , rejected_empty_locations
    , is_from_profile
    , uptime_bin
    , duration_bin
    , calls
    , lc.vertical_id
    , lc.logical_category_id
    , lc.logical_param1_id
    , lc.logical_param2_id
    , cm.category_id           
    , cm.subcategory_id                                        
    , cm.Param1_microcat_id as param1_id
    , cm.Param2_microcat_id as param2_id
    , cm.Param3_microcat_id as param3_id
    , cm.Param4_microcat_id as param4_id
    , case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id
    , case cl.level when 3 then cl.Location_id end                           as city_id
    , cl.LocationGroup_id as location_group_id
    , cl.Logical_Level as location_level_id
    , coalesce(acd.is_asd, False) as is_asd
    , acd.user_group_id      as asd_user_group_id
    , coalesce(usm.user_segment, ls.segment) as user_segment_market
from dma.cpa_calls_metrics c
left join dma.current_locations cl on cl.location_id = c.location_id

left join /*+jtype(h),distrib(l,a)*/ (
    select infmquery_id, logcat_id, microcat_id
    from infomodel.current_infmquery_category
    where infmquery_id in (
        select distinct infmquery_id
        from dma.cpa_calls_metrics
        where cast(event_date as date) between :first_date and :last_date
            and infmquery_id is not null
            --and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
    )
) ci
    on ci.infmquery_id = c.infmquery_id

left join dma.current_microcategories cm on cm.microcat_id = ci.microcat_id
left join dma.current_logical_categories lc on ci.logcat_id = lc.logcat_id

left join /*+jtype(h),distrib(l,r)*/ DMA.user_segment_market usm
    on  c.user_id = usm.user_id
    and lc.logical_category_id = usm.logical_category_id
    and cast(c.event_date as date) = usm.event_date
    and usm.reason_code is not null
    and usm.event_date between :first_date and :last_date
    -- and usm.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino

left join dict.segmentation_ranks ls
    on ls.logical_category_id = lc.logical_category_id
    and ls.is_default

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
	on acd.user_id = c.user_id
	and c.event_date between acd.active_from_date and acd.active_to_date
where cast(c.event_date as date) between :first_date and :last_date
    --and c.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino