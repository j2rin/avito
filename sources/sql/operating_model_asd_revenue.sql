select
    pur.event_date,
    pur.user_id,
    npsm.vertical_id,
    DATEDIFF('day', npsm.pro_paying_converted_date, pur.event_date) as days_after_pro_paying_convert,
    coalesce(cm.vertical_id = npsm.vertical_id, False) as is_payment_in_converted_vertical,
    ctt.transaction_type,
    ctt.transaction_subtype,
    ctt.product_type,
    ctt.product_subtype,
    pur.transaction_amount,
    pur.transaction_amount_net,
    pur.transaction_amount_net_adj
from dma.paying_user_report pur
join dma.new_pro_seller_metrics npsm on npsm.user_id = pur.user_id
    and pur.event_date between npsm.pro_paying_converted_date and npsm.pro_paying_converted_date+179
join dma.current_transaction_type ctt using(TransactionType_id)
left join dma.current_microcategories cm on pur.microcat_id = cm.microcat_id and cm.microcat_id != -1
where event_date::date between :first_date and :last_date
    and npsm.pro_paying_converted_date is not null
    and npsm.is_new_pro_seller_total
    and ctt.IsRevenue
