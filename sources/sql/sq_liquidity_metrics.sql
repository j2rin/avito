select
	event_date,
	cookie_id,
	item_id,
	delay,
	execution_date,
	source,
    destination,
	metric_name,
	metric_value
from DMA.sq_liquidity_metrics
where cast(event_date as date) between :first_date and :last_date
  and execution_month between date_trunc('month', :first_date) and date_trunc('month', :last_date) + interval'1'month