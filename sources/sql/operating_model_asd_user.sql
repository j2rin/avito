with new_pro_seller_metrics as (
    select  pro_paying_converted_date as event_date,
            user_id,
            vertical_id,
            logical_category_id,
            user_segment_market_paying as user_segment_market,
            is_new_pro_seller_total as is_seller_total,
            date_diff('day', pro_converted_date, pro_paying_converted_date) as days_to_paying_convert
    from dma.new_pro_seller_metrics m
    where cast(pro_paying_converted_date as date) between :first_date and :last_date
)
select
    'new_pro_paying_seller' as metric_group,
    m.event_date,
    m.user_id,
    m.vertical_id,
    m.logical_category_id,
    m.user_segment_market,
    m.is_seller_total,
    m.days_to_paying_convert,
    m.days_to_paying_convert < dp.days_to_paying_convert_095 as is_for_ttft
from new_pro_seller_metrics m
left join (
    select  event_date, vertical_id,
--             APPROXIMATE_PERCENTILE(days_to_paying_convert USING PARAMETERS percentile=0.95) as days_to_paying_convert_095 -- @vertica
--             approx_percentile(cast(days_to_paying_convert as real), 0.95) as days_to_paying_convert_095 -- @trino
    from new_pro_seller_metrics
    group by event_date, vertical_id
) dp
    on dp.event_date = m.event_date
    and dp.vertical_id = m.vertical_id
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
where cast(pro_reactivated_date as date) between :first_date and :last_date
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
where cast(pro_paying_reactivated_date as date) between :first_date and :last_date
    and pro_paying_reactivated_date is not null
UNION ALL
select
    'x_vertical_new_pro_seller' as metric_group,
    pro_converted_date as event_date,
    user_id,
    null as vertical_id,
    null as logical_category_id,
    null as user_segment_market,
    true as is_seller_total,
    null as days_to_paying_convert,
    null as is_for_ttft
from dma.x_vertical_new_pro_seller_metrics
where cast(pro_converted_date as date) between :first_date and :last_date
UNION ALL
select
    'x_vertical_new_pro_paying_seller' as metric_group,
    pro_paying_converted_date as event_date,
    user_id,
    null as vertical_id,
    null as logical_category_id,
    null as user_segment_market,
    true as is_seller_total,
    null as days_to_paying_convert,
    null as is_for_ttft
from dma.x_vertical_new_pro_seller_metrics
where cast(pro_paying_converted_date as date) between :first_date and :last_date
    and pro_paying_converted_date is not null
