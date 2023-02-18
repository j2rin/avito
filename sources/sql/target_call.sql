select
    tc.event_date::date,
    tc.call_time:: date,
    tc.buyer_id,
    tc.buyer_cookie_id,
    tc.platform_id,
    tc.seller_id,
    tc.item_id,
    tc.microcat_id,
    tc.location_id,
    tc.call_id,
    tc.call_type,
    tc.talk_duration,
    tc.is_target_call,
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
    cl.Logical_Level                                             as location_level_id
from DMA.target_call tc
left join DMA.current_microcategories cm on cm.microcat_id = tc.microcat_id
left join DMA.current_locations cl on cl.Location_id = tc.location_id
where call_time::date between :first_date and :last_date
