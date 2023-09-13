select /*+syntactic_join*/
    ss.event_date,
    ss.platform_id,
    ss.cookie_id,
    ss.user_id,
    ss.session_no,
    ss.microcat_id,
    ss.eventtype_ext                                                as eid,
    ss.prev_location_id,
    ss.location_id,
    ss.open_from as open_from_id,
    cast(ss.close_by as int) as close_by,
    ss.suspicious_change_threshold,
    ss.after_first_search,
    ss.mechanism_type,
    ss.events_count,
        case
        when cast(ss.close_by as INT) = 0 then 'close'
        when cast(ss.close_by as INT) = 1 then 'accept'
        when cast(ss.close_by as INT) = 2 then 'not accept'
        else 'NA'
        end as
    tooltip_close_type,
        case
        when ss.open_from in ('1', '7') then 'bad'
        when ss.after_first_search then 'suspicious'
        when ss.open_from != '1' and not ss.after_first_search then 'neutral'
        else 'NA'
        end as
    changing_quality_type,
        case
        when cl.logical_level < clp.logical_level then 'expanded'
        when cl.logical_level > clp.logical_level then 'detailed'
        when cl.logical_level = clp.logical_level then 'horizontal'
        end as
    changing_geo_type,
        case
        when ss.open_from = '0' then 'search'
        when ss.open_from = '1' then 'tooltip'
        when ss.open_from = '3' then 'my items'
        when ss.open_from = '5' then 'radius'
        when ss.open_from = '6' then 'app settings'
		when ss.open_from = '7' then 'laas tooltip'
        else 'other'
        end as
    open_from,
    time_span,
    ---
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
    cl.Logical_Level                                             as location_level_id,
    case clp.level when 3 then clp.ParentLocation_id else clp.Location_id end as prev_region_id,
    case clp.level when 3 then clp.Location_id end                            as prev_city_id,
    clp.LocationGroup_id                                         as prev_location_group_id,
    clp.City_Population_Group                                    as prev_population_group,
    clp.Logical_Level                                            as prev_location_level_id
from dma.location_changings                         ss
LEFT JOIN /*+jtype(h)*/ DMA.current_microcategories cm on cm.microcat_id = ss.microcat_id
LEFT JOIN /*+jtype(h)*/ DMA.current_locations       clp ON clp.Location_id = ss.prev_location_id
LEFT JOIN /*+jtype(h)*/ DMA.current_locations       cl ON cl.Location_id = ss.location_id
where cast(ss.event_date as date) between :first_date and :last_date
