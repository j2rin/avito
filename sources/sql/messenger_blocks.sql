with
am_client_day as (
    select user_id,
           active_from_date,
           active_to_date,
           (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
           user_group_id
    from DMA.am_client_day_versioned
),
usm as (
    select
        user_id,
        logical_category_id,
        user_segment,
        converting_date,
        lead(converting_date, 1, cast('2099-01-01' as date)) over(partition by user_id, logical_category_id order by converting_date) as next_converting_date
    from DMA.user_segment_market
)
select
    cast(t.event_date as date) as event_date,
    t.platform_id,
    ci.location_id,
    ci.Microcat_id,
    t.user_id,
    t.chat_Id,
    t.is_item_owner,
    t.is_first_block,
  -- Dimensions -----------------------------------------------------------------------------------------------------
    cm.vertical_id,
    cm.category_id,
    cm.subcategory_id,
    cm.logical_category_id,
    cm.Param1_microcat_id                                        as param1_id,
    cm.Param2_microcat_id                                        as param2_id,
    cm.Param3_microcat_id                                        as param3_id,
    cm.Param4_microcat_id                                        as param4_id,
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
    cl.LocationGroup_id                                          as location_group_id,
    cl.City_Population_Group                                     as population_group,
    cl.Logical_Level                                             as location_level_id,
    coalesce(acd.is_asd, False)                                       as is_asd,
    acd.user_group_id                                            as asd_user_group_id,
    coalesce(usm.user_segment, ls.segment)                            as user_segment_market
from DMA.messenger_blocks  t
JOIN dma.current_item as ci
    ON ci.item_id = t.item_id
left join DMA.current_locations cl
    ON cl.Location_id = ci.location_id
JOIN dma.current_microcategories as cm
    ON cm.microcat_id = ci.Microcat_id
left join am_client_day acd
    on t.user_Id = acd.user_id
    and cast(t.event_date as date) between acd.active_from_date and acd.active_to_date
left join usm
    on t.user_Id = usm.user_id
    and cm.logical_category_id = usm.logical_category_id
    and t.event_date >= converting_date and t.event_date < next_converting_date
left join  dict.segmentation_ranks ls
    on ls.logical_category_id = cm.logical_category_id
    and ls.is_default
where cast(t.event_date as date) between :first_date and :last_date
--and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
