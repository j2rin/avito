select /*+syntactic_join*/
    cs.event_date,
    cs.cookie_id,
    cs.user_id,
    cs.platform_id,
    cs.laas_rule,
    cs.laas_tooltip_type,
    cs.client_location_id,
    cs.was_tooltip_show,
    cs.answer,
    cs.laas_rule ilike '%search%' as search_rule,
    cs.laas_rule ilike '%coords_choice%' as coords_choice_rule,
    ---
    cl.LocationGroup_id                                       as location_group_id,
    cl.City_Population_Group                                  as population_group,
    cl.Logical_Level                                          as location_level_id
from dma.laas_stream                                 cs
LEFT JOIN /*+jtype(h)*/ DMA.current_locations       cl ON cl.Location_id = cs.location_id
where cs.event_date::date between :first_date and :last_date
