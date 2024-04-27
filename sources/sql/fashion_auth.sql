select *
from DMA.fashion_authentication
where 1=1
    and event_date::date between :first_date and :last_date