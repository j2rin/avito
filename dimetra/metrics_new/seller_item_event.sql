create fact seller_item_event as
select
    t.event_date::date as __date__,
    t.start_time::date                                       as start_date,
    t.last_activation_time::date                             as last_activation_date,
    *
from DMA.o_seller_item_event t
;