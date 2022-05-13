create fact favourite_sellers_totals as
select
    t.event_date as __date__,
    t.cnt_subscriptions_total,
    t.event_date,
    t.is_active,
    t.is_new,
    t.user_id as user,
    t.user_id,
    t.user_type
from dma.favourite_sellers_totals t
;

create metrics favourite_sellers_totals_user as
select
    sum(case when cnt_favourite_sellers_subscriptions_active_new_old > 0 then 1 end) as active_buyers_with_fs_subscriptions,
    sum(case when cnt_favourite_sellers_subscribers_active_new_old > 0 then 1 end) as active_sellers_with_fs_subscribers,
    sum(case when fs_subscriptions_per_buyer > 0 then 1 end) as buyers_with_fs_subscriptions,
    sum(case when fs_subscribers_per_seller > 0 then 1 end) as sellers_with_fs_subscribers
from (
    select
        user_id, user,
        sum(case when is_active = True and user_type = 'seller' and (is_new in (False, True)) then cnt_subscriptions_total end) as cnt_favourite_sellers_subscribers_active_new_old,
        sum(case when is_active = True and user_type = 'buyer' and (is_new in (False, True)) then cnt_subscriptions_total end) as cnt_favourite_sellers_subscriptions_active_new_old,
        sum(case when user_type = 'seller' and (is_active = False and is_new = False or is_active = False and is_new = True or is_active = True and is_new = False or is_active = True and is_new = True) then cnt_subscriptions_total end) as fs_subscribers_per_seller,
        sum(case when user_type = 'buyer' and (is_active = False and is_new = False or is_active = True and is_new = False or is_active = True and is_new = True) then cnt_subscriptions_total end) as fs_subscriptions_per_buyer
    from favourite_sellers_totals t
    group by user_id, user
) _
;

create metrics favourite_sellers_totals as
select
    sum(case when is_active = True and user_type = 'seller' and (is_new in (False, True)) then cnt_subscriptions_total end) as cnt_favourite_sellers_subscribers_active_new_old,
    sum(case when is_active = True and user_type = 'buyer' and (is_new in (False, True)) then cnt_subscriptions_total end) as cnt_favourite_sellers_subscriptions_active_new_old,
    sum(case when user_type = 'seller' and (is_active = False and is_new = False or is_active = False and is_new = True or is_active = True and is_new = False or is_active = True and is_new = True) then cnt_subscriptions_total end) as fs_subscribers_per_seller,
    sum(case when user_type = 'buyer' and (is_active = False and is_new = False or is_active = True and is_new = False or is_active = True and is_new = True) then cnt_subscriptions_total end) as fs_subscriptions_per_buyer
from favourite_sellers_totals t
;
