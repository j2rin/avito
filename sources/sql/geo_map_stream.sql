select
    ss.event_time                                             as event_date,
    ss.cookie_id,
    ss.user_id,
    ss.microcat_id,
    ss.platform_id,
    ss.searchevent_id,
    ss.location_id,
    ss.session_no,
    ss.item_cnt,
    ss.has_metro_filter,
    ss.has_road_filter,
    ss.has_district_filter,
    ss.has_price_filter,
    ss.has_usual_filter,
    ss.scrolls_zoom_levels,
    ss.pins_zoom_levels,
    ss.clusters,
    ss.pins,
    ss.zooms,
    ss.my_locs,
    ss.scrolls,
    ss.item_views,
    ss.contacts,
    ss.favorites,
    ss.nav_actions_to_contact,
    ss.nav_actions_to_item_view,
	ss.pins_to_contact,
	ss.pins_to_item_view,
    ss.pin_interesting_colored_in_green,
    ---
    cm.vertical_id                                            as vertical_id,
    cm.logical_category_id                                    as logical_category_id,
    cm.category_id                                            as category_id,
    cm.subcategory_id                                         as subcategory_id,
    cm.Param1_microcat_id                                     as param1_id,
    cm.Param2_microcat_id                                     as param2_id,
    cm.Param3_microcat_id                                     as param3_id,
    cm.Param4_microcat_id                                     as param4_id,
    decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id) as region_id,
    decode(cl.level, 3, cl.Location_id, null)                 as city_id,
    cl.LocationGroup_id                                       as location_group_id,
    cl.City_Population_Group                                  as population_group,
    cl.Logical_Level                                          as location_level_id
from dma.map_stream                                 ss
LEFT JOIN /*+jtype(h)*/ DMA.current_microcategories cm on cm.microcat_id = ss.microcat_id
LEFT JOIN /*+jtype(h)*/ DMA.current_locations       cl ON cl.Location_id = ss.location_id
where ss.event_time::date between :first_date and :last_date
