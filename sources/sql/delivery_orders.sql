select 
    co.*,
-- Dimensions -----------------------------------------------------------------------------------------------------
    clc.vertical_id                                              as vertical_id,
    cm.category_id                                               as category_id,
    cm.subcategory_id                                            as subcategory_id,
    cm.Param1_microcat_id                                        as param1_id,
    cm.Param2_microcat_id                                        as param2_id,
    cm.Param3_microcat_id                                        as param3_id,
    cm.Param4_microcat_id                                        as param4_id,
    clc.logical_category_id                                      as logical_category_id,
    clc.logical_param1_id                                        as logical_param1_id,
    clc.logical_param2_id                                        as logical_param2_id,
    --seller/item location
    cl.location_id                                               as location_id,
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
    cl.LocationGroup_id                                          as location_group_id,
    cl.City_Population_Group                                     as population_group,
    cl.Logical_Level                                             as location_level_id,
    --buyer location
    bl.location_id                                               as buyer_location_id,
    case bl.level when 3 then bl.ParentLocation_id else bl.Location_id end as buyer_region_id,
    case bl.level when 3 then bl.Location_id end                           as buyer_city_id,
    bl.LocationGroup_id                                          as buyer_location_group_id,
    bl.City_Population_Group                                     as buyer_population_group,
    bl.Logical_Level                                             as buyer_location_level_id
from dma.delivery_metric_for_ab co
left join dma.current_logical_categories clc using(logical_category_id)
left join dma.current_microcategories cm using(microcat_id)
left join dma.current_locations as cl on co.warehouse_location_id = cl.location_id
left join dma.current_locations as bl on co.buyer_location_id = bl.location_id
where co.status_date::date between :first_date::date and :last_date::date
