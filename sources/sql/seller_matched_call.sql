SELECT
    mac.observation_date as event_date,
    ci.user_id,
    mac.platform_id,
    mac.item_id,
    mac.microcat_id,
    mac.location_id,
    mac.observation_name,
    mac.observation_value,
    -- Dimensions -----------------------------------------------------------------------------------------------------
    cm.vertical_id                                               as vertical_id,
    cm.logical_category_id                                       as logical_category_id,
    cm.category_id                                               as category_id,
    cm.subcategory_id                                            as subcategory_id,
    cm.Param1_microcat_id                                        as param1_id,
    cm.Param2_microcat_id                                        as param2_id,
    cm.Param3_microcat_id                                        as param3_id,
    cm.Param4_microcat_id                                        as param4_id,
    decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id)    as region_id,
    decode(cl.level, 3, cl.Location_id, null)                    as city_id,
    cl.LocationGroup_id                                          as location_group_id,
    cl.City_Population_Group                                     as population_group,
    cl.Logical_Level                                             as location_level_id,
    mac.is_item_cpa,
    mac.is_user_cpa,
    mac.cpaaction_type
FROM dma.matched_anonymous_calls_metric_observation mac
JOIN /*+distrib(l,b)*/ (
    select ci.item_id, ci.user_id
    from DMA.current_item ci
    where item_id in (
        select item_id
        from DMA.matched_anonymous_calls_metric_observation
        where observation_date::date between :first_date and :last_date
    )
) ci on mac.item_id = ci.item_id
LEFT JOIN DMA.current_microcategories cm on cm.microcat_id   = mac.microcat_id
LEFT JOIN DMA.current_locations       cl ON cl.Location_id   = mac.location_id
WHERE mac.participant_type = 'visitor'
    and mac.observation_date::date between :first_date and :last_date
