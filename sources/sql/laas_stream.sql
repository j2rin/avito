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
    lower(cs.laas_rule) like '%search%' as search_rule,
    lower(cs.laas_rule) like '%coords_choice%' as coords_choice_rule,
    ---
    cl.LocationGroup_id                                       as location_group_id,
    cl.City_Population_Group                                  as population_group,
    cl.Logical_Level                                          as location_level_id
from dma.laas_stream                                 cs
LEFT JOIN /*+jtype(h)*/ DMA.current_locations       cl ON cl.Location_id = cs.location_id
where cast(cs.event_date as date) between :first_date and :last_date
    -- and event_week between date_trunc('week', :first_date) and date_trunc('week', :last_date) --@trino
