select
    'new_pro_paying_seller' as metric_group,
    pro_paying_converted_date as event_date,
    user_id,
    vertical_id,
    logical_category_id,
    user_segment_market_paying as user_segment_market,
    is_new_pro_seller_total as is_seller_total,
    DATEDIFF('day', pro_converted_date, pro_paying_converted_date) as days_to_paying_convert,
    days_to_paying_convert < PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY days_to_paying_convert) over (partition by event_date, vertical_id) as is_for_ttft
from dma.new_pro_seller_metrics
where event_date::date between :first_date and :last_date
    and pro_paying_converted_date is not null
UNION ALL
select
    'reactivated_pro_seller' as metric_group,
    pro_reactivated_date as event_date,
    user_id,
    vertical_id,
    logical_category_id,
    user_segment_market as user_segment_market,
    is_reactivated_pro_seller_total as is_seller_total,
    null as days_to_paying_convert,
    null as is_for_ttft
from dma.reactivated_pro_seller_metrics
where event_date::date between :first_date and :last_date
UNION ALL
select
    'reactivated_pro_paying_seller' as metric_group,
    pro_paying_reactivated_date as event_date,
    user_id,
    vertical_id,
    logical_category_id,
    user_segment_market_paying as user_segment_market,
    is_reactivated_pro_seller_total as is_seller_total,
    null as days_to_paying_convert,
    null as is_for_ttft
from dma.reactivated_pro_seller_metrics
where event_date::date between :first_date and :last_date
    and pro_paying_reactivated_date is not null
