select
    cs.event_date,
    cs.cookie_id,
    cs.user_id,
    cs.platform_id,
    cs.geopoint,
    cs.latitude,
    cs.longitude,
    cs.resolved,
    cs.accuracy,
    datediff('hour',cs.resolve_time, cs.event_date) as freshness_hours,
    cs.provider,
    cs.error,
    cs.eid,
    cs.city_id,
    cs.region_id,
    cs.cities_cnt,
    cs.regions_cnt,
    ---
    cl.LocationGroup_id                                       as location_group_id,
    cl.City_Population_Group                                  as population_group,
    cl.Logical_Level                                          as location_level_id
from dma.coordinates_stream                                 cs
LEFT JOIN /*+jtype(h)*/ DMA.current_locations       cl ON cl.Location_id = cs.city_id
where cast(cs.event_date as date) between :first_date and :last_date
