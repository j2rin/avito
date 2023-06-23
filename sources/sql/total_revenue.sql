select
    0 as user_id,
    ur.event_date,
    miq.vertical_id,
    ctt.transaction_type,
    ctt.transaction_subtype,
    ctt.product_subtype,
    ctt.product_type,
    ctt.is_classified,
    NULL as project_type,
    sum(ur.transaction_amount_net_adj) as amount_net_adj
from DMA.paying_user_report ur
join DMA.current_transaction_type ctt using(transactiontype_id)
left join dma.current_microcategories miq on ur.microcat_id = miq.microcat_id
where ur.user_id not in (select cu.user_id from dma.current_user cu where cu.IsTest)
    and ctt.IsRevenue
    and ur.event_date::date between :first_date and :last_date
group by 1,2,3,4,5,6,7,8
union all 
select 
    0 as user_id, 
    observation_date as event_date,
    vertical_id,
    NULL as transaction_type,
    NULL as transaction_subtype,
    NULL as product_subtype,
    NULL as product_type,
    false as is_classified,
    project_type,
    amount_net_adj
from dma.other_projects_revenue
where observation_date::date between :first_date and :last_date
union all
select
	0 as user_id,
    ps.actual_date::date as status_date,
    cm.vertical_id as vertical_id,
    NULL as transaction_type,
    NULL as transaction_subtype,
    NULL as product_subtype,
    NULL as product_type,
    false as is_classified,
    'delivery' as project_type,
    co.delivery_revenue/co.items_qty/1.2 as delivery_amount_net_adj --нормируем на кол-во айтемов в заказе, чтобы не дублировать выручку
from dma.current_order_item as coi
left join dma.current_order as co on co.deliveryorder_id = coi.deliveryorder_id
left join dma.current_microcategories as cm on coi.microcat_id = cm.microcat_id
join (
    --чтобы побороть дубли статусов по некоторым заказам, находим минимальную дату для каждого из статусов
    select
        deliveryorder_id,
        platformstatus,
        min(actual_date) as actual_date
    from dds.s_deliveryorder_platformstatus
    group by 1,2
) ps on ps.deliveryorder_id = coi.deliveryorder_id
where ps.actual_date::date between :first_date and :last_date
    --and not co.is_test
    --and not co.is_deleted
    --and not coi.is_deleted
    and ps.platformstatus = 'accepted'
union all
select
    0                           as user_id,
    event_date,
    500012                      as vertical_id,
    NULL                        as transaction_type,
    NULL                        as transaction_subtype,
    NULL                        as product_subtype,
    NULL                        as product_type,
    false                       as is_classified,
    'auto_auction'              as project_type,
    amount_net_adj
from (select terminated_at::date        as event_date
                , sum(bt_revenue)       as amount_net_adj
      from dma.qd_auto_report_lots
      where has_buyout = 1
            and buyout_amount > 0
      group by terminated_at::date
      ) t
where event_date::date between :first_date and :last_date
