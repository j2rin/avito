select /*+syntactic_join*/
	   event_date,
	   cookie_id,
	   item_id,
	   delay,
	   execution_date,
	   metric_name,
	   metric_value
from DMA.sq_track_metrics
where event_date::date between :first_date and :last_date
