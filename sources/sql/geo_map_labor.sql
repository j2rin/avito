select  observation_date as event_Date,
		platform_id,
	 	case when participant_type = 'visitor' then participant_id end as cookie_id,
  		case when participant_type = 'user'    then participant_id end as user_id,
  		participant_id,
  		session_no,
 		m.location_id,
 		m.microcat_id,
 		observation_name,
 		observation_value,
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
   from dma.map_stream_metric_observation m
  LEFT JOIN /*+jtype(h)*/ DMA.current_microcategories cm on cm.microcat_id   = m.microcat_id
  LEFT JOIN /*+jtype(h)*/ DMA.current_locations       cl ON cl.Location_id   = m.location_id
where event_Date::date between :first_date and :last_date
