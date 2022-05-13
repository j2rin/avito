create fact buyer_weighted as
select
    t.event_date as __date__,
    t.cookie_id,
    t.event_date,
    t.weight
from dma.vo_buyer_weighted t
;

create metrics buyer_weighted as
select
    sum(weight) as buyers_weighted
from buyer_weighted t
;
