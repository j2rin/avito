select * 
from DMA.premium_events_tracker
left join b2c_items bi on bi.item_id = pe.item_id
where 1=1
    and cast(event_date as date) between :first_date and :last_date
    --and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
