	select observation_date as event_date,
		   observation_name,
		   vertical_id,
		   logical_category_id,
		   participant_id as user_id,
		   observation_value
	from dma.ratings_logcat_metric_observation
where event_date::date between :first_date and :last_date
