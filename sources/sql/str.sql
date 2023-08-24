    select observation_date as event_date,
    	   platform_id,
    	   mac.location_id,
    	   mac.vertical_id,
    	   mac.logical_category_id,
    	   mac.category_id,
    	   mac.subcategory_id,
    	   mac.microcat_id,
    	   case when cookie_id is not null then cookie_id else ( case when participant_type = 'visitor' then participant_id end ) end as cookie_id,
  		   case when user_id is not null then user_id else ( case when participant_type = 'user' then participant_id end ) end as user_id,
  		   participant_id,
  		   observation_name,
  		   observation_value,
           has_short_video,
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
     FROM dma.str_metric_observation mac
    LEFT JOIN /*+jtype(h)*/ DMA.current_microcategories cm on cm.microcat_id   = mac.microcat_id
	LEFT JOIN /*+jtype(h)*/ DMA.current_locations       cl ON cl.Location_id   = mac.location_id
where event_date::date between :first_date and :last_date
