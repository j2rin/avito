create fact deal_confirmed as
select
    t.event_date::date as __date__,
    *
from dma.vo_confirmed_deals t
;

create metrics deal_confirmed as
select
    sum(1) as deal_confirmed
from deal_confirmed t
;
