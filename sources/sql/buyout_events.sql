select
    be.launch_id,
    be.event_date,
    be.item_id,
    nvl(cast(item_id as varchar), buyout_request_id) as entity_id,
    be.user_id,
    be.eid,
    be.banner_type,
    be.buyout_screen_type,
    be.segment,
    be.dispatch_cd,
    be.source,
    be.event_type,
    be.buyout_request_id,
    be.partner_id,
    be.partner_name,
    be.brand,
    be.location_id                                               as location_id,
    decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id)    as region_id,
    decode(cl.level, 3, cl.Location_id, null)                    as city_id,
    cl.LocationGroup_id                                          as location_group_id,
    cl.City_Population_Group                                     as population_group,
    cl.Logical_Level                                             as location_level_id
from dma.buyout_events be
left join dma.current_locations cl
    on be.location_id=cl.location_id
where 1=1
    and be.event_date::date between :first_date and :last_date
