create fact contact_deal_weight as
select
    t.event_date::date as __date__,
    *
from dma.vo_contact_deal_weight t
;

create metrics contact_deal_weight as
select
    sum(c_deal_logit) as contact_deal_logit,
    sum(c_deal_weight) as contact_deal_weight
from contact_deal_weight t
;

create metrics contact_deal_weight_cookie as
select
    sum(case when contact_deal_weight > 0 then 1 end) as user_contact_deal_weight
from (
    select
        cookie_id,
        sum(c_deal_weight) as contact_deal_weight
    from contact_deal_weight t
    group by cookie_id
) _
;
