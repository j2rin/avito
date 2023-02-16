select
    ss.platform_id,
    ss.event_date,
    ss.cookie_id,
    ss.user_id,
    ss.logical_category_id,
    ss.location_id,
    ss.action_type,
    ss.birthday,
    -- Dimensions -----------------------------------------------------------------------------------------------------
    cm.vertical_id                                               as vertical_id,
    cl.region_internal_id                                        as region_id,
    cl.city_internal_id                                          as city_id,
    cl.LocationGroup_id                                          as location_group_id,
    cl.City_Population_Group                                     as population_group,
    cl.Logical_Level                                             as location_level_id
from DMA.action_returned ss
left join /*+jtype(h)*/ DMA.current_logical_categories cm
    on cm.logcat_id = ss.logical_category_id
    and cm.level_name = 'LogicalCategory'
left join /*+jtype(h)*/ DMA.current_locations cl on cl.Location_id = ss.location_id
where ss.event_date between :first_date and :last_date
