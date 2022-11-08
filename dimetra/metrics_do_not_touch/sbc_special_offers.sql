create fact sbc_special_offers as
select
    t.discount_send_date::date as __date__,
    *
from dma.vo_seller_buyer_communication t
;

create metrics sbc_special_offers as
select
    sum(special_offers) as sbc_special_offers,
    sum(case when source = 1 then special_offers end) as sbc_special_offers_tariff,
    sum(case when source = 2 then special_offers end) as sbc_special_offers_vas
from sbc_special_offers t
;

create metrics sbc_special_offers_user_id as
select
    sum(case when sbc_special_offers > 0 then 1 end) as user_sbc_special_offers
from (
    select
        user_id,
        sum(special_offers) as sbc_special_offers
    from sbc_special_offers t
    group by user_id
) _
;
