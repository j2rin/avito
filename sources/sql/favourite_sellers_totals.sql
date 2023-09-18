select
    event_date,
    user_id,
    user_type,
    first_subscription_time,
    cnt_subscriptions_total,
    is_new,
    is_active,
    is_visitor
from dma.favourite_sellers_totals
where cast(event_date as date) between :first_date and :last_date
