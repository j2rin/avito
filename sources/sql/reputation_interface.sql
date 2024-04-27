select
    cast(rs.event_timestamp as date) as event_date
    , rs.user_id
    , rs.role
    , rs.eid
    , rs.from_page
    , rs.source
    -- dimensions
    , decode(rs.quality_level, 'high', 'green', 'medium', 'yellow', 'low', 'red') as reputation_color
    , hp.platform_id
    , cl.location_id
    , case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id
    , case cl.level when 3 then cl.Location_id end                           as city_id
    , cl.LocationGroup_id                                                    as location_group_id
    , cl.City_Population_Group                                               as population_group
    , cl.Logical_Level                                                       as location_level_id
    , coalesce(asd.is_asd, False)                                            as is_asd
    , asd.asd_user_group_id                                                  as asd_user_group_id
from dma.repsys_events rs
join dds.H_Platform hp on hp.external_id = rs.platform
join dma."current_user" cu on rs.user_id = cu.user_id
left join dma.current_locations cl on cu.location_id = cl.location_id
left join (
    select
        asd.user_id,
        (asd.personal_manager_team is not null and asd.user_is_asd_recognised) as is_asd,
        asd.user_group_id as asd_user_group_id,
        asd.active_from_date,
        asd.active_to_date
    from DMA.am_client_day_versioned asd
    where true
        and asd.active_from_date <= :last_date
        and asd.active_to_date >= :first_date
) asd on rs.user_id = asd.user_id and cast(rs.event_timestamp as date) between asd.active_from_date and asd.active_to_date
where 1=1
and cast(event_timestamp as date) between cast(:first_date as date) and cast(:last_date as date)
-- and event_month between date_trunc('month' , :first_date) and date_trunc('month' , :last_date) -- @trino
and eid in (7256, 7257, 7258, 7259)
