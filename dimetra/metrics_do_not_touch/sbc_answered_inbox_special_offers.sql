create fact sbc_answered_inbox_special_offers as
select
    t.answer_time::date as __date__,
    *
from dma.vo_seller_buyer_communication t
;

create metrics sbc_answered_inbox_special_offers as
select
    sum(case when answer = 'accept_discount' then special_offers end) as accepted_inbox_sbc_special_offers,
    sum(case when first_message = True then special_offers end) as fm_inbox_sbc_special_offers
from sbc_answered_inbox_special_offers t
;

create metrics sbc_answered_inbox_special_offers_buyer_id as
select
    sum(case when accepted_inbox_sbc_special_offers > 0 then 1 end) as user_accepted_inbox_sbc_special_offers
from (
    select
        buyer_id,
        sum(case when answer = 'accept_discount' then special_offers end) as accepted_inbox_sbc_special_offers
    from sbc_answered_inbox_special_offers t
    group by buyer_id
) _
;
