select event_date, 
       ci.user_id,
       sc.item_id,
-- ------ dimensions ----------------------------------------------------
      cm.microcat_id, 
      cl.location_id, 
      cm.vertical_id                                               as vertical_id,
      cm.logical_category_id                                       as logical_category_id,
      cm.category_id                                               as category_id,
      cm.subcategory_id                                            as subcategory_id,
      cm.Param1_microcat_id                                        as param1_id,
      cm.Param2_microcat_id                                        as param2_id, 
      case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
      case cl.level when 3 then cl.Location_id end                           as city_id,
      cl.LocationGroup_id                                          as location_group_id,
      cl.City_Population_Group                                     as population_group,
      cl.Logical_Level                                             as location_level_id
from dma.services_active_items_calendar sc 
join dma.current_item ci on ci.item_id = sc.item_id
left join dma.current_microcategories cm on cm.microcat_id = ci.microcat_id
left join dma.current_locations cl on cl.location_id = ci.location_id
where cast(event_date as date) between :first_date and :last_date