select 
    launch_id as _,
    date(status_date_sold) as event_date,
    count(distinct agency_lead_ext) as premier_partner_deals
from dma.current_pp_agency_lead_lifetime 
where 1=1
    and status_date_sold is not null
    and (status_date_declined is null or status_date_declined < status_date_sold )
    and status_date_attached >= date('2023-05-01')
    and date(status_date_sold) between date(:first_date) and date(:last_date)
group by 1, 2
