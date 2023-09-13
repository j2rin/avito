select
	event_date,
	cookie_id,
	item_id,
	delay,
	execution_date,
	source,
	metric_name,
	metric_value
from DMA.sq_track_metrics
where cast(event_date as date) between :first_date and :last_date
