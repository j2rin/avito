select
	event_date,
	event_timestamp,
    donation_sum,
	fund,
    user_id
from DMA.charity_donations_events
where eid = 5059
where cast(event_date as date) between :first_date and :last_date
