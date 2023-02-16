create fact short_rent_item_trx as
select
    t.event_date::date as __date__,
    *
from dma.vo_short_rent_item_trx t
;

create metrics short_rent_item_trx as
select
    sum(1) as short_rent_items_with_trx
from short_rent_item_trx t
;
