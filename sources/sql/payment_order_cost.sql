with delivery_status_date as ( --чтобы побороть дубли статусов по некоторым заказам, находим минимальную дату для каждого из статусов
    select
        deliveryorder_id,
        platformstatus,
        min(actual_date) as actual_date
    from dds.s_deliveryorder_platformstatus
    where cast(actual_date as date) <= :last_date
    group by 1, 2
    having min(actual_date) >= :first_date
    order by deliveryorder_id

),
order_data as (
select purchase_ext, min(platform_id) as platform_id ,min(buyer_id) as buyer_id, min(create_date) as create_date
from dma.current_order
group by 1
)
,orders as (
    select distinct deliveryorder_id
    from delivery_status_date
),
buyers as (
    select distinct buyer_id
    from dma.current_order
    where deliveryorder_id in (select deliveryorder_id from orders)
),
sellers as (
    select distinct seller_id
    from dma.current_order_item
    where deliveryorder_id in (select deliveryorder_id from orders))
select
    cast(cbcm.create_date as date) as create_date,
    co.buyer_id as user_id,
    cast(co.create_date as date) < coalesce(du.pay_date, cast('9999-12-21' as date)) as is_delivery_paid_new,
    coalesce(has_avito_bindings, FALSE) as has_avito_bindings,
    billing_order_ext,
    cbcm.items_price,
    co.platform_id,
    payment_commission_calculated,
    commission_calculated,
    case when payment_method = 'SBP' then TRUE else FALSE end as is_sbp,
    case when is_mir = 1 then TRUE else FALSE end as is_mir,
    case when has_refund > 0 then TRUE else FALSE end as has_refund
    from dma.current_billing_cost_mp cbcm
    join order_data co on cbcm.billing_order_ext = co.purchase_ext
        left join /*+distrib(l,a)*/ (
        select
            buyer_id,
            min(coalesce(pay_date, confirm_date)) as pay_date,
            min(accept_date) as accept_date
        from dma.current_order
        where true
            and buyer_id in (select buyer_id from buyers)
            and (coalesce(pay_date, confirm_date) <= :last_date or accept_date <= :last_date)
        group by 1
    ) du
        on du.buyer_id = co.buyer_id
    left join /*+distrib(l,a)*/ (
    select
        co.purchase_id,
        co.purchase_ext,
        MAX(case when expired_date >= date('2022-03-01') and expired_date >= (create_date - interval '5' year) and create_date between status_start_at and coalesce(status_end_at, create_date) then True else False end) as has_avito_bindings,
        SUM(case when expired_date >= date('2022-03-01') and expired_date >= (create_date - interval '5' year) and create_date between status_start_at and coalesce(status_end_at, create_date) then 1 else 0 end) as cnt_bindings
    from dma.current_order co
    left join dma.user_payment_bindings pb on pb.user_id = co.buyer_id
    where true
        and pb.external_source_provider_id in (18)
        and pb.is_available = True
               and co.deliveryorder_id in (select deliveryorder_id from orders)
    group by 1,2
) ub on cbcm.billing_order_ext = ub.purchase_ext
    where cast(cbcm.create_date as date) between :first_date and :last_date
