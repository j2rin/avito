select /*+syntactic_join*/
    cs.event_date,
    cs.cookie_id,
    cs.user_id,
    cs.platform_id,
    cs.item_id,
    cs.microcat_id,
    cs.distance,
    cs.is_outlier,
    ---
    cm.vertical_id                                               as vertical_id,
    cm.logical_category_id                                       as logical_category_id,
    cm.category_id                                               as category_id,
    cm.subcategory_id                                            as subcategory_id,
    ---
    cs.user_city_id 										  as city_id,
    decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id) as region_id,
    cl.LocationGroup_id                                       as location_group_id,
    cl.City_Population_Group                                  as population_group,
    cl.Logical_Level                                          as location_level_id,
    ---
    cs.item_city_id,
    decode(cli.level, 3, cli.ParentLocation_id, cli.Location_id) as item_region_id,
    cli.LocationGroup_id                                       as item_location_group_id
from dma.buyers_items_distance                                 cs
LEFT JOIN /*+jtype(h)*/ DMA.current_locations       cl ON cl.Location_id = cs.user_city_id
LEFT JOIN /*+jtype(h)*/ DMA.current_locations       cli ON cli.Location_id = cs.item_city_id
left join /*+jtype(h)*/ DMA.current_microcategories cm on cm.microcat_id = cs.microcat_id
where event_date::date between :first_date and :last_date