create fact geo_map_stream as
select
    t.clusters,
    t.contacts,
    t.cookie_id as cookie,
    t.cookie_id,
    t.event_date,
    t.has_district_filter,
    t.has_metro_filter,
    t.has_price_filter,
    t.has_road_filter,
    t.has_usual_filter,
    t.item_cnt,
    t.item_views,
    t.my_locs,
    t.nav_actions_to_contact,
    t.nav_actions_to_item_view,
    t.pins,
    t.pins_to_contact,
    t.pins_to_item_view,
    t.pins_zoom_levels,
    t.scrolls,
    t.scrolls_zoom_levels,
    t.session_no as session,
    t.zooms
from dma.vo_geo_map_stream t
;

create metrics geo_map_stream as
select
    sum(case when contacts > 0 then 1 end) as cnt_map_with_c,
    sum(case when item_views > 0 then 1 end) as cnt_map_with_iv,
    sum(nav_actions_to_contact) as cnt_nav_actions_to_c,
    sum(nav_actions_to_item_view) as cnt_nav_actions_to_iv,
    sum(case when pins_zoom_levels > 0 then pins end) as cnt_pins_with_zoom_levels,
    sum(pins_zoom_levels) as cnt_pins_zoom_levels,
    sum(case when scrolls_zoom_levels > 0 then scrolls end) as cnt_scrolls_with_zoom_levels,
    sum(scrolls_zoom_levels) as cnt_scrolls_zoom_levels,
    sum(case when item_cnt = -1 then 1 end) as errors_map,
    sum(clusters) as map_clusters,
    sum(case when item_cnt = 0 then 1 end) as map_empty_search,
    sum(case when (has_district_filter = True or has_metro_filter = True or has_road_filter = True) then 1 end) as map_local_geo,
    sum(my_locs) as map_my_locs,
    sum(ifnull(clusters, 0) + ifnull(my_locs, 0) + ifnull(scrolls, 0) + ifnull(zooms, 0)) as map_nav_actions,
    sum(case when (has_price_filter = True or has_usual_filter = True) then 1 end) as map_price_rubricator_filters,
    sum(scrolls) as map_scrolls,
    sum(1) as map_searches,
    sum(zooms) as map_zooms,
    sum(pins) as pin_clicks,
    sum(pins_to_contact) as pins_to_c,
    sum(pins_to_item_view) as pins_to_iv
from geo_map_stream t
;

create metrics geo_map_stream_session as
select
    sum(case when map_searches > 0 then 1 end) as map_searches_sessions,
    sum(case when map_searches > 1 then 1 end) as map_sessions_1plus_maps,
    sum(case when map_searches > 2 then 1 end) as map_sessions_2plus_maps,
    sum(case when map_searches > 3 then 1 end) as map_sessions_3plus_maps,
    sum(case when pin_clicks > 0 then 1 end) as pin_clicks_sessions
from (
    select
        cookie_id, session,
        sum(1) as map_searches,
        sum(pins) as pin_clicks
    from geo_map_stream t
    group by cookie_id, session
) _
;

create metrics geo_map_stream_cookie as
select
    sum(case when map_searches > 0 then 1 end) as map_users,
    sum(case when map_searches > 1 then 1 end) as map_users_1plus_maps,
    sum(case when map_searches > 2 then 1 end) as map_users_2plus_maps,
    sum(case when map_searches > 3 then 1 end) as map_users_3plus_maps,
    sum(case when pin_clicks > 0 then 1 end) as pin_clickers,
    sum(case when map_empty_search > 0 then 1 end) as user_map_empty_search,
    sum(case when errors_map > 0 then 1 end) as user_map_error,
    sum(case when map_local_geo > 0 then 1 end) as user_map_local_geo,
    sum(case when map_price_rubricator_filters > 0 then 1 end) as user_map_price_rubricator_filters
from (
    select
        cookie_id, cookie,
        sum(case when item_cnt = -1 then 1 end) as errors_map,
        sum(case when item_cnt = 0 then 1 end) as map_empty_search,
        sum(case when (has_district_filter = True or has_metro_filter = True or has_road_filter = True) then 1 end) as map_local_geo,
        sum(case when (has_price_filter = True or has_usual_filter = True) then 1 end) as map_price_rubricator_filters,
        sum(1) as map_searches,
        sum(pins) as pin_clicks
    from geo_map_stream t
    group by cookie_id, cookie
) _
;
