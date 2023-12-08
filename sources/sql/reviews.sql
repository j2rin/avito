select
    cast(cr.create_date as date) as event_date,
 	rpc.platform_id,
 	cr.location_id,
 	cm.vertical_id,
 	cm.category_id,
 	cm.subcategory_id,
 	cm.logical_category_id,
    cm.microcat_id,
  	rpc.cookie_id,
  	cr.from_user_id as user_id,
	cr.to_user_id as seller_id,
	reviewstatus,
  	cr.stage,
  	cr.score,
  	cr.photo_count,
  	rpc.review_add_trigger,
  	rpc.page_from,
  	cr.review_id,
 	-- Dimensions -----------------------------------------------------------------------------------------------------
	cm.Param1_microcat_id                                        as param1_id,
	cm.Param2_microcat_id                                        as param2_id,
	cm.Param3_microcat_id                                        as param3_id,
	cm.Param4_microcat_id                                        as param4_id,
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
	cl.LocationGroup_id                                          as location_group_id,
	cl.City_Population_Group                                     as population_group,
	cl.Logical_Level                                             as location_level_id
from dma.current_reviews as cr
left join /*+jtype(fm)*/ dma.review_params_clickstream  as rpc on cr.review_id   = rpc.review_id
left join /*+jtype(h)*/  dma.current_microcategories    as cm  on cr.microcat_id = cm.microcat_id
left join /*+jtype(h)*/  dma.current_locations          as cl  on cr.Location_id = cl.location_id
where cast(cr.create_date as date) between :first_date and :last_date
--and create_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
