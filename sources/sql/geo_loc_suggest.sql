select /*+syntactic_join*/
    ss.event_date,
    ss.platform_id,
    ss.cookie_id,
    ss.microcat_id,
    ss.FromBlock,
    ss.FromPage,
    ss.LocationSuggestText,
    ss.locationInput,
    length(ss.locationInput) LocationInputLength,
    ss.location_id,
    ss.events,
    ---
    cl.LocationGroup_id                                          as location_group_id,
    cl.City_Population_Group                                     as population_group,
    cl.Logical_Level                                             as location_level_id
from dma.location_suggest_click                      ss
LEFT JOIN /*+jtype(h)*/ DMA.current_locations       cl ON cl.Location_id = ss.location_id
where event_date::date between :first_date and :last_date
