	  select observation_date as event_date,
	  		 platform_id,
	  		 cv.location_id,
	  		 participant_id as user_id,
	  		 express_cv_form_open,
		     express_cv_started,
		     express_cv_started_net,
		     express_cv_published,
		     express_cv_views,
		     contacts_paid_express_cv,
		     contacts_paid_amount_express_cv,
		     -- Dimensions -----------------------------------------------------------------------------------------------------
             case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
             case cl.level when 3 then cl.Location_id end                           as city_id,
	      	 cl.LocationGroup_id                                          as location_group_id,
	      	 cl.City_Population_Group                                     as population_group,
	      	 cl.Logical_Level                                             as location_level_id
	    from dma.express_cv_metric_observation cv
  LEFT JOIN /*+jtype(h)*/ DMA.current_locations       cl ON cl.Location_id   = cv.location_id
where cast(observation_date as date) between :first_date and :last_date
