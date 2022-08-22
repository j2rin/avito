create fact buyer_confirmation_deals as
select
    t.event_time::date as __date__,
    *
from dma.vo_confirmation_deals t
;

create metrics buyer_confirmation_deals as
select
    sum(case when dealconfirmationstate in ('buyer_confirmed_deal', 'buyer_rejected_deal') then 1 end) as buyer_deals_answered_buyer,
    sum(case when dealconfirmationstate in ('seller_confirmed_deal', 'seller_rejected_deal') then 1 end) as buyer_deals_answered_seller,
    sum(case when dealconfirmationstate = 'buyer_confirmed_deal' then 1 end) as buyer_deals_confirmed_buyer,
    sum(case when dealconfirmationstate = 'seller_confirmed_deal' then 1 end) as buyer_deals_confirmed_seller,
    sum(case when dealconfirmationstate = 'seller_is_working' then 1 end) as buyer_deals_is_working,
    sum(case when dealconfirmationstate in ('buyer_deal_postponed', 'buyer_deal_postponed_2') then 1 end) as buyer_deals_postponed_buyer,
    sum(case when dealconfirmationstate = 'buyer_rejected_deal' then 1 end) as buyer_deals_rejected_buyer,
    sum(case when dealconfirmationstate = 'seller_rejected_deal' then 1 end) as buyer_deals_rejected_seller,
    sum(case when dealconfirmationstate in ('seller_confirmed_work', 'seller_rejected_work') then 1 end) as buyer_works_answered_seller,
    sum(case when dealconfirmationstate = 'seller_confirmed_work' then 1 end) as buyer_works_confirmed_seller,
    sum(case when dealconfirmationstate = 'seller_rejected_work' then 1 end) as buyer_works_rejected_seller
from buyer_confirmation_deals t
;

create metrics buyer_confirmation_deals_user as
select
    sum(case when buyer_deals_answered_buyer > 0 then 1 end) as buyers_answered_deal,
    sum(case when buyer_deals_confirmed_buyer > 0 then 1 end) as buyers_confirmed_deal,
    sum(case when buyer_deals_postponed_buyer > 0 then 1 end) as buyers_deal_postponed,
    sum(case when buyer_deals_rejected_buyer > 0 then 1 end) as buyers_rejected_deal,
    sum(case when buyer_deals_answered_seller > 0 then 1 end) as buyers_with_sellers_answered_deal,
    sum(case when buyer_works_answered_seller > 0 then 1 end) as buyers_with_sellers_answered_work,
    sum(case when buyer_deals_confirmed_seller > 0 then 1 end) as buyers_with_sellers_confirmed_deal,
    sum(case when buyer_works_confirmed_seller > 0 then 1 end) as buyers_with_sellers_confirmed_work,
    sum(case when buyer_deals_is_working > 0 then 1 end) as buyers_with_sellers_is_working,
    sum(case when buyer_deals_rejected_seller > 0 then 1 end) as buyers_with_sellers_rejected_deal,
    sum(case when buyer_works_rejected_seller > 0 then 1 end) as buyers_with_sellers_rejected_work
from (
    select
        buyer_id,
        sum(case when dealconfirmationstate in ('buyer_confirmed_deal', 'buyer_rejected_deal') then 1 end) as buyer_deals_answered_buyer,
        sum(case when dealconfirmationstate in ('seller_confirmed_deal', 'seller_rejected_deal') then 1 end) as buyer_deals_answered_seller,
        sum(case when dealconfirmationstate = 'buyer_confirmed_deal' then 1 end) as buyer_deals_confirmed_buyer,
        sum(case when dealconfirmationstate = 'seller_confirmed_deal' then 1 end) as buyer_deals_confirmed_seller,
        sum(case when dealconfirmationstate = 'seller_is_working' then 1 end) as buyer_deals_is_working,
        sum(case when dealconfirmationstate in ('buyer_deal_postponed', 'buyer_deal_postponed_2') then 1 end) as buyer_deals_postponed_buyer,
        sum(case when dealconfirmationstate = 'buyer_rejected_deal' then 1 end) as buyer_deals_rejected_buyer,
        sum(case when dealconfirmationstate = 'seller_rejected_deal' then 1 end) as buyer_deals_rejected_seller,
        sum(case when dealconfirmationstate in ('seller_confirmed_work', 'seller_rejected_work') then 1 end) as buyer_works_answered_seller,
        sum(case when dealconfirmationstate = 'seller_confirmed_work' then 1 end) as buyer_works_confirmed_seller,
        sum(case when dealconfirmationstate = 'seller_rejected_work' then 1 end) as buyer_works_rejected_seller
    from buyer_confirmation_deals t
    group by buyer_id
) _
;
