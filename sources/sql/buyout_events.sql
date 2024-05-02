select
    be.launch_id,
    be.event_date,
    be.item_id,
    from_big_endian_64(xxhash64(cast(coalesce(cast(item_id as varchar), buyout_request_id, '') as varbinary))) as entity_id,
    be.user_id,
    be.eid,
    be.banner_type,
    be.buyout_screen_type,
--     be.segment,
    be.dispatch_cd,
    be.source,
    be.event_type,
    be.buyout_request_id,
    be.partner_id,
    be.partner_name,
    be.brand,
    be.location_id                                                           as location_id,
    case when cl.level = 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case when cl.level = 3 then cl.Location_id else null end                 as city_id,
    cl.LocationGroup_id                                                      as location_group_id,
    cl.City_Population_Group                                                 as population_group,
    cl.Logical_Level                                                         as location_level_id
from dma.buyout_events be
left join dma.current_locations cl
    on be.location_id=cl.location_id
where 1=1
    and cast(be.event_date as date) between :first_date and :last_date
    -- and be.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
