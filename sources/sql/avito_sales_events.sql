select 
	event_date,
	eid,
	business_platform as platform_id,
   	user_id,
   	cookie_id,
   	from_page
from dma.avito_sales_events
where event_date between :first_date and :last_date
