select observation_date as event_date,
 	   participant_id as cookie_id,
 	   observation_name,
 	   observation_value,
 	   is_participant_new,
 	   is_participant_authorized,
 	   platform_id,
 	   ss.microcat_id,
 	   ss.location_id,
 	   session_source_id,
 	   last_nondirect_session_source_id,
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
  from dma.session_source_metric_observation ss
  LEFT JOIN /*+jtype(h)*/ DMA.current_microcategories cm on cm.microcat_id   = ss.microcat_id
  LEFT JOIN /*+jtype(h)*/ DMA.current_locations       cl ON cl.Location_id   = ss.location_id
where cast(observation_date as date) between :first_date and :last_date
