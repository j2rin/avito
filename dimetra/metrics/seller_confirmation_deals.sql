create fact seller_confirmation_deals as
select
    t.event_time as __date__,
    t.dealconfirmationstate,
    t.event_time,
    t.seller_id,
    t.seller_id as user
from dma.vo_confirmation_deals t
;

create metrics seller_confirmation_deals as
select
    sum(case when dealconfirmationstate in ('buyer_confirmed_deal', 'buyer_rejected_deal') then 1 end) as seller_deals_answered_buyer,
    sum(case when dealconfirmationstate in ('seller_confirmed_deal', 'seller_rejected_deal') then 1 end) as seller_deals_answered_seller,
    sum(case when dealconfirmationstate = 'buyer_confirmed_deal' then 1 end) as seller_deals_confirmed_buyer,
    sum(case when dealconfirmationstate = 'seller_confirmed_deal' then 1 end) as seller_deals_confirmed_seller,
    sum(case when dealconfirmationstate = 'seller_is_working' then 1 end) as seller_deals_is_working,
    sum(case when dealconfirmationstate in ('buyer_deal_postponed', 'buyer_deal_postponed_2') then 1 end) as seller_deals_postponed_buyer,
    sum(case when dealconfirmationstate = 'buyer_rejected_deal' then 1 end) as seller_deals_rejected_buyer,
    sum(case when dealconfirmationstate = 'seller_rejected_deal' then 1 end) as seller_deals_rejected_seller,
    sum(case when dealconfirmationstate in ('seller_confirmed_work', 'seller_rejected_work') then 1 end) as seller_works_answered_seller,
    sum(case when dealconfirmationstate = 'seller_confirmed_work' then 1 end) as seller_works_confirmed_seller,
    sum(case when dealconfirmationstate = 'seller_rejected_work' then 1 end) as seller_works_rejected_seller
from seller_confirmation_deals t
;

create metrics seller_confirmation_deals_user as
select
    sum(case when seller_deals_answered_seller > 0 then 1 end) as sellers_answered_deal,
    sum(case when seller_works_answered_seller > 0 then 1 end) as sellers_answered_work,
    sum(case when seller_deals_confirmed_seller > 0 then 1 end) as sellers_confirmed_deal,
    sum(case when seller_works_confirmed_seller > 0 then 1 end) as sellers_confirmed_work,
    sum(case when seller_deals_is_working > 0 then 1 end) as sellers_is_working,
    sum(case when seller_deals_rejected_seller > 0 then 1 end) as sellers_rejected_deal,
    sum(case when seller_works_rejected_seller > 0 then 1 end) as sellers_rejected_work,
    sum(case when seller_deals_answered_buyer > 0 then 1 end) as sellers_with_buyers_answered_deal,
    sum(case when seller_deals_confirmed_buyer > 0 then 1 end) as sellers_with_buyers_confirmed_deal,
    sum(case when seller_deals_postponed_buyer > 0 then 1 end) as sellers_with_buyers_deal_postponed,
    sum(case when seller_deals_rejected_buyer > 0 then 1 end) as sellers_with_buyers_rejected_deal
from (
    select
        seller_id, user,
        sum(case when dealconfirmationstate in ('buyer_confirmed_deal', 'buyer_rejected_deal') then 1 end) as seller_deals_answered_buyer,
        sum(case when dealconfirmationstate in ('seller_confirmed_deal', 'seller_rejected_deal') then 1 end) as seller_deals_answered_seller,
        sum(case when dealconfirmationstate = 'buyer_confirmed_deal' then 1 end) as seller_deals_confirmed_buyer,
        sum(case when dealconfirmationstate = 'seller_confirmed_deal' then 1 end) as seller_deals_confirmed_seller,
        sum(case when dealconfirmationstate = 'seller_is_working' then 1 end) as seller_deals_is_working,
        sum(case when dealconfirmationstate in ('buyer_deal_postponed', 'buyer_deal_postponed_2') then 1 end) as seller_deals_postponed_buyer,
        sum(case when dealconfirmationstate = 'buyer_rejected_deal' then 1 end) as seller_deals_rejected_buyer,
        sum(case when dealconfirmationstate = 'seller_rejected_deal' then 1 end) as seller_deals_rejected_seller,
        sum(case when dealconfirmationstate in ('seller_confirmed_work', 'seller_rejected_work') then 1 end) as seller_works_answered_seller,
        sum(case when dealconfirmationstate = 'seller_confirmed_work' then 1 end) as seller_works_confirmed_seller,
        sum(case when dealconfirmationstate = 'seller_rejected_work' then 1 end) as seller_works_rejected_seller
    from seller_confirmation_deals t
    group by seller_id, user
) _
;
