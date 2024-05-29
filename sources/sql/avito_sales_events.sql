select 
	event_date,
	eid,
	business_platform as platform_id,
   	user_id,
   	cookie_id,
   	from_page
from dma.avito_sales_events
where event_date between :first_date and :last_date
-- and event_year between date_trunc('year', date(:first_date)) and date_trunc('year', date(:last_date)) -- @trino