SELECT
    observation_date as event_date,
    case when participant_type = 'visitor' then participant_id end as cookie_id,
    case when participant_type = 'user' 	 then participant_id end as user_id,
    participant_id,
    platform_id,
    item_id,
    mac.microcat_id,
    mac.location_id,
    observation_name,
    observation_value,
    -- Dimensions -----------------------------------------------------------------------------------------------------
    cm.vertical_id                                               as vertical_id,
    cm.logical_category_id                                       as logical_category_id,
    cm.category_id                                               as category_id,
    cm.subcategory_id                                            as subcategory_id,
    cm.Param1_microcat_id                                        as param1_id,
    cm.Param2_microcat_id                                        as param2_id,
    cm.Param3_microcat_id                                        as param3_id,
    cm.Param4_microcat_id                                        as param4_id,
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
    cl.LocationGroup_id                                          as location_group_id,
    cl.City_Population_Group                                     as population_group,
    cl.Logical_Level                                             as location_level_id,
    mac.is_item_cpa,
    mac.is_user_cpa,
    mac.cpaaction_type,
    mac.user_segment											 as user_segment_market
FROM dma.matched_anonymous_calls_metric_observation mac
LEFT JOIN /*+jtype(h)*/ DMA.current_microcategories cm on cm.microcat_id   = mac.microcat_id
LEFT JOIN /*+jtype(h)*/ DMA.current_locations       cl ON cl.Location_id   = mac.location_id
where mac.observation_date between :first_date and :last_date
    --and observation_month between date_trunc('month', :first_date) and date_trunc('month', :last_date) --@trino
