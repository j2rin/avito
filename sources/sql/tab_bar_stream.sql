select *
from DMA.tab_bar_stream
where true
    and event_date::date between :first_date and :last_date