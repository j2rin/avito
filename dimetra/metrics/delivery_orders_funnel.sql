create fact delivery_orders_funnel as
select
    t.create_date as __date__,
    t.buyer_id,
    t.create_date,
    t.deliveryorder_id,
    t.is_accepted,
    t.is_confirmed,
    t.is_created,
    t.is_paid,
    t.is_performed,
    t.is_received
from dma.vo_delivery_orders t
;

create metrics delivery_orders_funnel as
select
    sum(case when is_accepted = True then 1 end) as buyer_delivery_items_accepted_funnel,
    sum(case when is_confirmed = True then 1 end) as buyer_delivery_items_confirmed_funnel,
    sum(case when is_created = True then 1 end) as buyer_delivery_items_created_funnel,
    sum(case when is_paid = True then 1 end) as buyer_delivery_items_paid_funnel,
    sum(case when is_performed = True then 1 end) as buyer_delivery_items_performed_funnel,
    sum(case when is_received = True then 1 end) as buyer_delivery_items_received_funnel
from delivery_orders_funnel t
;

create metrics delivery_orders_funnel_deliveryorder_id as
select
    sum(case when buyer_delivery_items_accepted_funnel > 0 then 1 end) as buyer_delivery_orders_accepted_funnel,
    sum(case when buyer_delivery_items_confirmed_funnel > 0 then 1 end) as buyer_delivery_orders_confirmed_funnel,
    sum(case when buyer_delivery_items_created_funnel > 0 then 1 end) as buyer_delivery_orders_created_funnel,
    sum(case when buyer_delivery_items_paid_funnel > 0 then 1 end) as buyer_delivery_orders_paid_funnel,
    sum(case when buyer_delivery_items_performed_funnel > 0 then 1 end) as buyer_delivery_orders_performed_funnel,
    sum(case when buyer_delivery_items_received_funnel > 0 then 1 end) as buyer_delivery_orders_received_funnel
from (
    select
        buyer_id, deliveryorder_id,
        sum(case when is_accepted = True then 1 end) as buyer_delivery_items_accepted_funnel,
        sum(case when is_confirmed = True then 1 end) as buyer_delivery_items_confirmed_funnel,
        sum(case when is_created = True then 1 end) as buyer_delivery_items_created_funnel,
        sum(case when is_paid = True then 1 end) as buyer_delivery_items_paid_funnel,
        sum(case when is_performed = True then 1 end) as buyer_delivery_items_performed_funnel,
        sum(case when is_received = True then 1 end) as buyer_delivery_items_received_funnel
    from delivery_orders_funnel t
    group by buyer_id, deliveryorder_id
) _
;
