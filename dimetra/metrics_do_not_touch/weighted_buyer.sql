create fact weighted_buyer as
select
    t.event_date::date as __date__,
    *
from dma.vo_weighted_buyer_metric t
;

create metrics weighted_buyer as
select
    sum(observation_value) as weighted_buyer
from weighted_buyer t
;
