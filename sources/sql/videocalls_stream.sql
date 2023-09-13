select
    vs.event_date,
    vs.cookie_id,
    vs.user_id,
    vs.platform_id,
    vs.item_id,
    ci.microcat_id,
    cl.location_id,
    case when eid = 5629 then 1 end as videocalls_contact,
    case when eid = 5630 then 1 end as videocalls_iv,
    -- Dimensions -----------------------------------------------------------------------------------------------------
    cm.vertical_id                                               as vertical_id,
    cm.logical_category_id                                       as logical_category_id,
    cm.category_id                                               as category_id,
    cm.subcategory_id                                            as subcategory_id,
    cm.Param1_microcat_id                                        as param1_id,
    cm.Param2_microcat_id                                        as param2_id,
    cm.Param3_microcat_id                                        as param3_id,
    cm.Param4_microcat_id                                        as param4_id,
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
    cl.LocationGroup_id                                          as location_group_id,
    cl.City_Population_Group                                     as population_group,
    cl.Logical_Level                                             as location_level_id
from DMA.videocalls_stream vs

JOIN /*+distrib(l,b)*/ (
    select ci.item_id, ci.microcat_id, ci.location_id
    from DMA.current_item ci
    where item_id in (
        select item_id
        from DMA.videocalls_stream
        where cast(event_date as date) between :first_date and :last_date
    )
) ci on vs.item_id = ci.item_id

left join DMA.current_microcategories cm on cm.microcat_id = ci.microcat_id
left join DMA.current_locations cl on cl.Location_id = ci.location_id

where cast(vs.event_date as date) between :first_date and :last_date
