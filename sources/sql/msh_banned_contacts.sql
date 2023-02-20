-- explain
select
    eventdate as event_date,
    bc.item_id,
    bc.user_id,
    bc.external_item_id,
    bc.category_id,
    bc.location_id,
    cm.vertical_id,
    cm.subcategory_id,
    cm.logical_category_id,
    cm.microcat_id,
    contacts,
    -- Dimensions -----------------------------------------------------------------------------------------------------
    cm.Param1_microcat_id                                        as param1_id,
    cm.Param2_microcat_id                                        as param2_id,
    cm.Param3_microcat_id                                        as param3_id,
    cm.Param4_microcat_id                                        as param4_id,
    decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id)    as region_id,
    decode(cl.level, 3, cl.Location_id, null)                    as city_id,
    cl.LocationGroup_id                                          as location_group_id,
    cl.City_Population_Group                                     as population_group,
    cl.Logical_Level                                             as location_level_id,
    lc.logical_param1_id,
    lc.logical_param2_id
from dma.banned_contacts bc
JOIN dma.current_item ci USING(item_id)
LEFT JOIN DMA.current_microcategories cm USING(microcat_id)
LEFT JOIN DMA.current_locations       cl on cl.location_id=bc.location_id
LEFT JOIN dma.current_logical_categories lc on lc.logcat_id = cm.logical_Category_id
where event_date::date between :first_date and :last_date
