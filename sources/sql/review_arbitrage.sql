select
    event_date,
    ar.cookie_id,
 	ar.platform_id,
  	ar.user_id,
  	is_auto,
  	is_initiator_reopen,
  	is_other_reopen,
  	is_both_reopen,
    who_is_initiator 											as initiator,
    files,
    use_in_rating,
    arbitrageresolution,
 	-- Dimensions -----------------------------------------------------------------------------------------------------
	ar.location_id,
 	cm.vertical_id,
 	cm.category_id,
 	cm.subcategory_id,
 	cm.logical_category_id,
    ar.microcat_id,
	cm.Param1_microcat_id                                        as param1_id,
	cm.Param2_microcat_id                                        as param2_id,
	cm.Param3_microcat_id                                        as param3_id,
	cm.Param4_microcat_id                                        as param4_id,
	decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id)    as region_id,
	decode(cl.level, 3, cl.Location_id, null)                    as city_id,
	cl.LocationGroup_id                                          as location_group_id,
	cl.City_Population_Group                                     as population_group,
	cl.Logical_Level                                             as location_level_id,
 	-- Observations ---------------------------------------------------------------------------------------------------
	arbitrage_created,
    arbitrage_resolved,
    review_arbitrage_open_attempts
from dma.arbitrage_metric_observation as ar
    left join /*+jtype(h)*/  dma.current_microcategories    as cm  on ar.microcat_id = cm.microcat_id
    left join /*+jtype(h)*/  dma.current_locations          as cl  on ar.Location_id = cl.location_id
where ar.event_date::date between :first_date and :last_date
