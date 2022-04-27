create enrichment location_tree as
select
    decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id) as region_id,
    decode(cl.level, 3, cl.Location_id, null)                 as city_id,
    cl.LocationGroup_id                                       as location_group_id,
    cl.City_Population_Group                                  as population_group,
    cl.Logical_Level                                          as location_level_id
from :fact_table                t
left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations cl on cl.Location_id = ss.location_id
hierarchy (
    (region_id, city_id)
);
