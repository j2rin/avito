    select observation_date as event_date,
           microcat_id,
  		   participant_id,
  		   backlog_hours,
  		   items_processed_before_ttl,
  		   items_processed,
  		   agent_items_day,
  		   agent_line_time_h
	from dma.moder_metric_observation
where cast(observation_date as date) between :first_date and :last_date
