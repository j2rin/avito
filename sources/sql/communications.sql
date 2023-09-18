select observation_date as event_date,
	   participant_id as user_id,
	   phone_location_id,
	   item_location_id,
	   anonnumber_calls,
	   anonnumber_success_calls,
	   anonnumber_success_talks,
	   anonnumber_useless_talks,
	   anonnumber_usefull_talks,
	   anonnumber_long_talks,
	   anonnumber_calls_duration,
	   anonnumber_success_calls_duration,
	   anonnumber_talks_duration,
	   anonnumber_success_talks_duration,
	   ss.microcat_id,
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
	   cl.Logical_Level                                             as location_level_id,
       case pcl.level when 3 then pcl.ParentLocation_id else pcl.Location_id end as phone_region_id,
       case pcl.level when 3 then pcl.Location_id end                            as phone_city_id,
	   pcl.LocationGroup_id                                          as phone_location_group_id,
	   pcl.City_Population_Group                                     as phone_population_group,
	   pcl.Logical_Level                                             as phone_location_level_id
  from dma.communications_metric_observation ss
  LEFT JOIN /*+jtype(h)*/ DMA.current_microcategories cm on cm.microcat_id   = ss.microcat_id
  LEFT JOIN /*+jtype(h)*/ DMA.current_locations       cl ON cl.Location_id   = ss.item_location_id
  LEFT JOIN /*+jtype(h)*/ DMA.current_locations       pcl ON pcl.Location_id   = ss.phone_location_id
where cast(observation_date as date) between :first_date and :last_date
