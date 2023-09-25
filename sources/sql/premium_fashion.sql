select *
from DMA.premium_events_tracker
where 1=1
    and event_date::date between :first_date and :last_date