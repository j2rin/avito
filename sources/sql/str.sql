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
           buyer_cluster, 
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
     FROM dma.str_metric_observation mac
    LEFT JOIN /*+jtype(h)*/ DMA.current_microcategories cm on cm.microcat_id   = mac.microcat_id
    LEFT JOIN /*+jtype(h)*/ DMA.current_locations       cl ON cl.Location_id   = mac.location_id
    where cast(observation_date as date) between :first_date and :last_date
        -- and observation_year between date_trunc('year', date(:first_date)) and date_trunc('year', date(:last_date)) --@trino
