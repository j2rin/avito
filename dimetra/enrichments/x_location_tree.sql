create enrichment location_tree as
select
    decode(clx.level, 3, clx.ParentLocation_id, clx.Location_id) as x_region_id,
    decode(clx.level, 3, clx.Location_id, null)                  as x_city_id,
    clx.LocationGroup_id                                         as x_location_group_id,
    clx.City_Population_Group                                    as x_population_group,
    clx.Logical_Level                                            as x_location_level_id
from :fact_table t
left join DMA.current_locations clx on clx.Location_id = t.x_location_id
;