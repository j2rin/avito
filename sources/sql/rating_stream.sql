select
  	rs.event_date,
  	rs.platform_id,
  	rs.location_id,
   	cm.vertical_id,
 	cm.category_id,
 	cm.subcategory_id,
 	cm.logical_category_id,
    cm.microcat_id,
  	rs.cookie_id,
  	rs.user_id,
  	rs.rating,
  	rs.is_visible,
  	rs.item_rating,
  	rs.item_views,
    rs.contacts,
    rs.bt_clicks,
    rs.contacts_with_review_list_view,
 	-- Dimensions -----------------------------------------------------------------------------------------------------
	cm.Param1_microcat_id                                        as param1_id,
	cm.Param2_microcat_id                                        as param2_id,
	cm.Param3_microcat_id                                        as param3_id,
	cm.Param4_microcat_id                                        as param4_id,
	decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id)    as region_id,
	decode(cl.level, 3, cl.Location_id, null)                    as city_id,
	cl.LocationGroup_id                                          as location_group_id,
	cl.City_Population_Group                                     as population_group,
	cl.Logical_Level                                             as location_level_id
from dma.rating_stream as rs
left join /*+jtype(h)*/  dma.current_microcategories    as cm  on rs.microcat_id = cm.microcat_id
left join /*+jtype(h)*/  dma.current_locations          as cl  on rs.Location_id = cl.location_id
where rs.event_date::date between :first_date and :last_date
