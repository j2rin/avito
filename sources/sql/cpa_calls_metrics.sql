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
    , decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id) as region_id
    , decode(cl.level, 3, cl.Location_id, null) as city_id
    , cl.LocationGroup_id as location_group_id
    , cl.Logical_Level as location_level_id
    , nvl(acd.is_asd, False) as is_asd
    , acd.user_group_id      as asd_user_group_id
    , nvl(usm.user_segment, ls.segment) as user_segment_market
from dma.cpa_calls_metrics c
left join dma.current_locations cl using(location_id)

left join /*+jtype(h),distrib(l,a)*/ (
    select infmquery_id, logcat_id, microcat_id
    from infomodel.current_infmquery_category
    where infmquery_id in (
        select distinct infmquery_id
        from dma.cpa_calls_metrics
        where event_date::date between :first_date and :last_date
            and infmquery_id is not null
    )
) ci
    on ci.infmquery_id = c.infmquery_id

left join dma.current_microcategories cm using(microcat_id)
left join dma.current_logical_categories lc on ci.logcat_id = lc.logcat_id

left join /*+jtype(h),distrib(l,r)*/ (
    select
        usm.user_id,
        usm.logical_category_id,
        usm.user_segment,
        usm.from_date,
        usm.to_date
    from (
        select
            user_id,
            logical_category_id,
            user_segment,
            converting_date as from_date,
            lead(converting_date, 1, '20990101') over(partition by user_id, logical_category_id order by converting_date) as to_date
        from DMA.user_segment_market
        where true
            and user_id in (
                select distinct user_id from dma.cpa_calls_metrics
                where event_date::date between :first_date and :last_date
            )
            and converting_date <= :last_date::date
    ) usm
    where usm.to_date >= :first_date::date
) usm
    on  c.user_id = usm.user_id
    and c.event_date::date >= usm.from_date and c.event_date::date < usm.to_date
    and lc.logical_category_id = usm.logical_category_id

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

where event_date::date between :first_date and :last_date
