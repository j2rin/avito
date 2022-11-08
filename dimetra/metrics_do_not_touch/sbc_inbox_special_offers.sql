create fact sbc_inbox_special_offers as
select
    t.discount_send_date::date as __date__,
    *
from dma.vo_seller_buyer_communication t
;

create metrics sbc_inbox_special_offers as
select
    sum(special_offers) as inbox_sbc_special_offers,
    sum(case when source = 1 then special_offers end) as inbox_sbc_special_offers_tariff,
    sum(case when source = 2 then special_offers end) as inbox_sbc_special_offers_vas
from sbc_inbox_special_offers t
;

create metrics sbc_inbox_special_offers_buyer_id as
select
    sum(case when inbox_sbc_special_offers > 0 then 1 end) as user_inbox_sbc_special_offers
from (
    select
        buyer_id,
        sum(special_offers) as inbox_sbc_special_offers
    from sbc_inbox_special_offers t
    group by buyer_id
) _
;
