with am_client_day as (
    select user_id,
           active_from_date,
           active_to_date,
           (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
           user_group_id
    from DMA.am_client_day_versioned
    where active_from_date::date <= :last_date
        and active_to_date::date >= :first_date
),
usm as (
    select user_id, logical_category_id, user_segment, converting_date,
        lead(converting_date, 1, '20990101') over(partition by user_id, logical_category_id order by converting_date) as next_converting_date
    from DMA.user_segment_market
    where converting_date::date <= :last_date
)
select
    m.event_date,
    m.eid,
    m.platform_id,
    m.cookie_id,
    m.user_id,
    m.location_id,
    m.message_type,
    m.report_reason,
    m.source,
    m.action_type_id,
    m.event_count,
    m.microcat_id,
    -- Dimensions -----------------------------------------------------------------------------------------------------
    cm.vertical_id,
    cm.category_id,
    cm.subcategory_id,
    cm.logical_category_id,
    cm.Param1_microcat_id                                        as param1_id,
    cm.Param2_microcat_id                                        as param2_id,
    cm.Param3_microcat_id                                        as param3_id,
    cm.Param4_microcat_id                                        as param4_id,
    decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id)    as region_id,
    decode(cl.level, 3, cl.Location_id, null)                    as city_id,
    cl.LocationGroup_id                                          as location_group_id,
    cl.City_Population_Group                                     as population_group,
    cl.Logical_Level                                             as location_level_id,
    nvl(acd.is_asd, False)                                       as is_asd,
    acd.user_group_id                                            as asd_user_group_id,
    nvl(usm.user_segment, ls.segment)                            as user_segment_market
from DMA.messenger_stream m
left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cm
		on cm.microcat_id = m.microcat_id
left join /*+jtype(h),distrib(l,b)*/ dict.segmentation_ranks ls
		on ls.logical_category_id = cm.logical_category_id
		and ls.is_default
left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations cl
		ON cl.Location_id = m.location_id
left join /*+jtype(h),distrib(l,a)*/ am_client_day acd
		on m.user_Id = acd.user_id
		and m.event_date between acd.active_from_date and acd.active_to_date
left join /*+distrib(l,a)*/ usm
        on m.user_id = usm.user_id
        and cm.logical_category_id = usm.logical_category_id
		and m.event_date::TIMESTAMP >= converting_date and m.event_date::TIMESTAMP < next_converting_date
where m.event_date::date between :first_date and :last_date
