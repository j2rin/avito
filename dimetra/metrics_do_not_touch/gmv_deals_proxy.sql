create fact gmv_deals_proxy as
select
    t.event_date::date as __date__,
    *
from dma.vo_gmv_deals_proxy t
;

create metrics gmv_deals_proxy as
select
    sum(gmv_volume) as gmv,
    sum(proxy_deals) as proxy_deals
from gmv_deals_proxy t
;
