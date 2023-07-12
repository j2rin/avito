with /*+ENABLE_WITH_CLAUSE_MATERIALIZATION */
delivery_status_date as ( --чтобы побороть дубли статусов по некоторым заказам, находим минимальную дату для каждого из статусов
    select
        deliveryorder_id,
        platformstatus,
        min(actual_date) as actual_date
    from dds.s_deliveryorder_platformstatus
    where actual_date::date <= :last_date
    group by 1, 2
    having min(actual_date) >= :first_date
    order by 1
),
orders as (
    select distinct deliveryorder_id
    from delivery_status_date
    order by 1
),
buyers as (
    select distinct buyer_id
    from dma.current_order
    where deliveryorder_id in (select deliveryorder_id from orders)
    order by 1
),
sellers as (
    select distinct seller_id
    from dma.current_order_item
    where deliveryorder_id in (select deliveryorder_id from orders)
    order by 1
),
cic as (
        select infmquery_id, logcat_id
        from infomodel.current_infmquery_category
        where infmquery_id in (
            select distinct infmquery_id
            from dma.current_order_item
            where deliveryorder_id in (select deliveryorder_id from orders)
                and infmquery_id is not null
        )
    order by 1,2),
acd as (
        select
            user_id,
            active_from_date,
            active_to_date,
            (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
            user_group_id
        from DMA.am_client_day_versioned
        where active_from_date <= :last_date
            and active_to_date >= :first_date
            and user_id in (select seller_id from sellers)
    order by 1,2),
du as (
        select
            buyer_id,
            min(coalesce(pay_date, confirm_date)) as pay_date,
            min(accept_date) as accept_date
        from dma.current_order
        where true
            --and is_test is false
            --and not is_deleted
            and (coalesce(pay_date, confirm_date) <= :last_date or accept_date <= :last_date)
            and buyer_id in (select buyer_id from buyers)
        group by 1
        order by 1
    ),
usm as (
    select
        user_id,
        logical_category_id,
        user_segment,
        converting_date as from_date,
        lead(converting_date, 1, '20990101') over(partition by user_id, logical_category_id order by converting_date) as to_date
    from DMA.user_segment_market
    where true
        and converting_date <= :last_date::date
        and user_id in (select seller_id from sellers)
    order by 1
),
ub as (
    select
        co.purchase_id,
        MAX(case when expired_date >= '2022-03-01' and expired_date >= (create_date - interval '5 years') and create_date between status_start_at and coalesce(status_end_at, create_date) then True else False end) as has_avito_bindings,
        SUM(case when expired_date >= '2022-03-01' and expired_date >= (create_date - interval '5 years') and create_date between status_start_at and coalesce(status_end_at, create_date) then 1 else 0 end) as cnt_bindings
    from dma.current_order co
    left join dma.user_payment_bindings pb on pb.user_id = co.buyer_id
    where true
        and pb.external_source_provider_id in (18)
        and pb.is_available = True
        and co.deliveryorder_id in (select deliveryorder_id from orders)
    group by 1
    order by 1
),
pre as (
    select
        co.create_date::date as create_date,
        ps.actual_date::date as status_date,
        co.buyer_id,
        co.create_date < coalesce(du.pay_date, '9999-12-21'::date) as is_delivery_paid_new,
        co.create_date < coalesce(du.accept_date, '9999-12-21'::date) as is_delivery_accepted_new,
        coi.seller_id,
        nvl(acd.is_asd, False) as is_asd,
        acd.user_group_id      as asd_user_group_id,
        co.deliveryorder_id,
        co.purchase_id,
        coi.deliveryorderproduct_id,
        coi.item_id,
        coi.item_price,
        co.delivery_revenue/co.items_qty/1.2 as delivery_revenue_no_vat, --нормируем на кол-во айтемов в заказе, чтобы не дублировать выручку
        co.safedeal_comission/co.items_qty as safedeal_comission_no_vat, --нормируем на кол-во айтемов в заказе, чтобы не дублировать комиссию
        co.delivery_comission/co.items_qty as delivery_comission_no_vat, --нормируем на кол-во айтемов в заказе, чтобы не дублировать комиссию
        co.approximate_delivery_provider_cost/co.items_qty/1.2 as approximate_delivery_provider_cost_no_vat, --нормируем на кол-во айтемов в заказе, чтобы не дублировать стоимость доставки
        co.real_delivery_provider_cost/co.items_qty/1.2 as real_delivery_provider_cost_no_vat, --нормируем на кол-во айтемов в заказе, чтобы не дублировать стоимость доставки
        co.delivery_discount/co.items_qty/1.2 as delivery_discount_no_vat, --нормируем на кол-во айтемов в заказе, чтобы не дублировать стоимость скидку на доставку
        case
            when create_date::date >= '2020-08-01' --просто мы начали писать approximate_delivery_provider_cost только в середине июля
            then (co.delivery_revenue/1.2 - co.safedeal_comission - co.delivery_comission - co.approximate_delivery_provider_cost/1.2)/co.items_qty
        end as approximate_delivery_margin,
        case
            when create_date::date >= '2020-08-01' --просто мы начали писать approximate_delivery_provider_cost только в середине июля
            then (co.delivery_revenue/1.2 - co.safedeal_comission - co.delivery_comission - coalesce(co.real_delivery_provider_cost, co.approximate_delivery_provider_cost)/1.2)/co.items_qty
        end as real_delivery_margin,
        coi.seller_commission,
  		case when co.workflow ilike '%b2c%' then coi.seller_commission/1.2 end as b2c_white_commission_no_vat,
        coi.trx_commission/1.2 as trx_commission_no_vat,
        case when co.workflow ilike '%b2c%' then coi.seller_commission end as b2c_white_commission,
        coi.trx_commission as trx_commission,
        co.current_status as status,
        case when co.workflow ilike '%marketplace%' then 'marketplace' else co.workflow end as delivery_workflow,
        delivery_service,
        co.platform_id,
        case
            when buyer_location_id <> warehouse_location_id then true
            else false
        end as is_intercity,
        --флаги статусов
        case when co.create_date = ps.actual_date then True else False end as is_created, --просто статусы создания заказы есть и new и approved и created - чтобы не дублировались проверяем на совпадение с датой создания заказа
        case when ps.platformstatus = 'paid' then True else False end is_paid,
        case
            when co.workflow in ('delivery-c2c', 'delivery-c2c-courier') and ps.platformstatus = 'confirmed' then True
            when co.workflow in ('marketplace-pvz', 'marketplace', 'delivery-b2c') and ps.platformstatus = 'placed' then True
            else False
        end is_confirmed,
        case when ps.platformstatus = 'performed' then True else False end is_performed,
        case when ps.platformstatus in ('delivered', 'provided') and ps.actual_date = co.deliver_date then True else False end is_provided, --зачистка от дублей, которая есть и на сторое dma.current_order
        case when ps.platformstatus = 'received' then True else False end is_received,
        case when ps.platformstatus = 'accepted' then True else False end is_accepted,
        --флаги отмен и возвратов
        case when ps.platformstatus = 'canceled' then True else False end is_canceled,
        case
            when co.workflow = 'delivery-c2c' and ps.platformstatus = 'voided' then True
            when co.workflow in ('marketplace-pvz', 'marketplace', 'delivery-b2c', 'delivery-c2c-courier') and ps.platformstatus = 'rejected' then True
            else False
        end is_voided,
        case when ps.platformstatus = 'unperformed' then True else False end is_unperformed,
        case
            when co.workflow = 'delivery-c2c-courier' and ps.platformstatus = 'on_return' then True
            when co.workflow in ('marketplace-pvz', 'marketplace', 'delivery-b2c', 'delivery-c2c') and ps.platformstatus = 'return_performed' then True
            else False
        end is_return_performed,
        case
            when co.workflow = 'delivery-c2c' and ps.platformstatus = 'on_delivery_return' then True
            when co.workflow in ('marketplace-pvz', 'marketplace', 'delivery-b2c') and ps.platformstatus = 'return_delivered' then True
            else False
        end is_return_delivered,
        case
            when co.workflow in ('delivery-c2c', 'delivery-c2c-courier') and ps.platformstatus = 'returned' then True
            when co.workflow in ('marketplace-pvz', 'marketplace', 'delivery-b2c') and ps.platformstatus = 'return_accepted' then True
            else False
        end is_returned,
        case when ps.platformstatus = 'unconfirmed' then True else False end is_unconfirmed,
        cm.microcat_id,
        coi.is_new, --новый ли товар
        case when delivery_discount > 0 then True else False end as is_delivery_discount, --флаг скидки
        co.items_qty,
        -- Dimensions -----------------------------------------------------------------------------------------------------
        clc.vertical_id                                              as vertical_id,
        cm.category_id                                               as category_id,
        cm.subcategory_id                                            as subcategory_id,
        cm.Param1_microcat_id                                        as param1_id,
        cm.Param2_microcat_id                                        as param2_id,
        cm.Param3_microcat_id                                        as param3_id,
        cm.Param4_microcat_id                                        as param4_id,
        clc.logical_category_id                                      as logical_category_id,
        clc.logical_param1_id                                        as logical_param1_id,
        clc.logical_param2_id                                        as logical_param2_id,
        --seller/item location
        cl.location_id                                               as location_id,
        decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id)    as region_id,
        decode(cl.level, 3, cl.Location_id, null)                    as city_id,
        cl.LocationGroup_id                                          as location_group_id,
        cl.City_Population_Group                                     as population_group,
        cl.Logical_Level                                             as location_level_id,
        --buyer location
        bl.location_id                                               as buyer_location_id,
        decode(bl.level, 3, bl.ParentLocation_id, bl.Location_id)    as buyer_region_id,
        decode(bl.level, 3, bl.Location_id, null)                    as buyer_city_id,
        bl.LocationGroup_id                                          as buyer_location_group_id,
        bl.City_Population_Group                                     as buyer_population_group,
        bl.Logical_Level                                             as buyer_location_level_id,
  		--is_cart
  		is_cart
    from dma.current_order_item as coi
    join /*+distrib(l,a)*/ delivery_status_date as ps on ps.deliveryorder_id = coi.deliveryorder_id
    left join /*+distrib(l,a)*/ cic
        on cic.infmquery_id = coi.infmquery_id
    left join /*+distrib(l,a)*/ dma.current_logical_categories clc on clc.logcat_id = cic.logcat_id
    left join /*+distrib(l,l)*/ dma.current_order as co on co.deliveryorder_id = coi.deliveryorder_id
    left join /*+distrib(l,a)*/ dma.current_microcategories as cm on coi.microcat_id = cm.microcat_id
    left join /*+distrib(l,a)*/ dma.current_locations as cl on co.warehouse_location_id = cl.location_id
    left join /*+distrib(l,a)*/ dma.current_locations as bl on co.buyer_location_id = bl.location_id
    left join /*+distrib(l,a)*/ acd on acd.user_id = coi.seller_id and co.create_date::date between acd.active_from_date and acd.active_to_date
    left join /*+distrib(l,a)*/ du on du.buyer_id = co.buyer_id
    order by seller_id, create_date, logical_category_id
),
cdd3 as (
    select deliveryorder_id, discount_value
    from dma.delivery_discounts
        where campaign_name ilike '%bonus_cashback%' and deliveryorder_id in (select deliveryorder_id from pre)
    order by 1
),
cds as (
    select deliveryorder_id,
threefirst_discount, bonus_discount, promocode_discount, c2c_seller_discount, 
exmail_discount, seller_comission, total_subsidies, threefirst_subsidies, 
bonus_subsidies, promocode_subsidies, additional_tax, exmail_subsidies,
total_threefirst_subsidies, total_exmail_subsidies, total_promocode_subsidies,
threefirst_subsidies_saved, exmail_subsidies_saved, promocode_subsidies_saved
    from dma.current_delivery_subsidies
        where deliveryorder_id in (select deliveryorder_id from pre)
    order by 1
)
select /*+syntactic_join*/
    pre.*,
    coalesce(usm.user_segment, ls.segment) as user_segment_market,
    ------ cкидки
    threefirst_discount/items_qty as threefirst_discount,  --нормируем на кол-во айтемов в заказе
    bonus_discount/items_qty as bonus_discount,
    cdd3.discount_value/items_qty as bonus_cashback,
    promocode_discount/items_qty as promocode_discount,
    c2c_seller_discount/items_qty as c2c_seller_discount,
    exmail_discount/items_qty as exmail_discount,
    ------ флаг скидки
    case when threefirst_discount > 0 then True else False end as is_threefirst_discount,
    case when bonus_discount > 0 then True else False end as is_bonus_discount,
    case when cdd3.discount_value is not null then True else False end as is_bonus_cashback,
    case when promocode_discount > 0 then True else False end as is_promocode_discount,
    case when seller_comission > 0 then True else False end as is_c2c_seller_discount,
    case when exmail_discount > 0 then True else False end as is_exmail_discount,
    ------ субсидии
    total_subsidies/items_qty as total_subsidies,--нормируем на кол-во айтемов в заказе
    -------------- subsidies (субсидии c экономией от скидки с2с_seller_discount)
    threefirst_subsidies/items_qty as threefirst_subsidies,
    bonus_subsidies/items_qty as bonus_subsidies,
    promocode_subsidies/items_qty as promocode_subsidies_wo_tax,
    (promocode_subsidies + additional_tax)/items_qty as promocode_subsidies,
    exmail_subsidies/items_qty as exmail_subsidies,
    -------------- total_subsidies (субсидии без экономии от скидки с2с_seller_discount)
    total_threefirst_subsidies/items_qty as total_threefirst_subsidies,
    total_exmail_subsidies/items_qty as total_exmail_subsidies,
    total_promocode_subsidies/items_qty as total_promocode_subsidies_wo_tax,
    (total_promocode_subsidies + additional_tax)/items_qty as total_promocode_subsidies,
    -------------- saved_subsidies
    threefirst_subsidies_saved/items_qty as threefirst_subsidies_saved,
    exmail_subsidies_saved/items_qty as exmail_subsidies_saved,
    promocode_subsidies_saved/items_qty as promocode_subsidies_saved,
    ------ привязки в контуре авито
    coalesce(has_avito_bindings, false) as has_avito_bindings
from pre
left join /*+distrib(l,a)*/ usm
    on  pre.seller_id = usm.user_id
    and pre.create_date >= usm.from_date and pre.create_date < usm.to_date
    and pre.logical_category_id = usm.logical_category_id
left join /*+distrib(l,a)*/ dict.segmentation_ranks as ls on ls.logical_category_id = pre.logical_category_id and ls.is_default
left join /*+distrib(l,a)*/ cdd3 on pre.deliveryorder_id = cdd3.deliveryorder_id
left join /*+distrib(l,a)*/ cds on pre.deliveryorder_id = cds.deliveryorder_id
left join /*+distrib(l,a)*/ ub on pre.purchase_id = ub.purchase_id

