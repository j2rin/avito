select 
	*
from dma.avito_sales_events
where event_date between :first_date and :last_date
