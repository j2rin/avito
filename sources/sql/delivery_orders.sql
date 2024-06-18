select 
    status_date,
    create_date,
    status_time,
    buyer_id,
    is_delivery_paid_new,
    is_delivery_accepted_new,
    seller_id,
    is_asd,
    asd_user_group_id,
    deliveryorder_id,
    purchase_id,
    deliveryorderproduct_id,
    item_id,
    item_price,
    delivery_revenue_no_vat,
    safedeal_comission_no_vat,
    delivery_comission_no_vat,
    approximate_delivery_provider_cost_no_vat,
    real_delivery_provider_cost_no_vat,
    delivery_discount_no_vat,
    approximate_delivery_margin,
    real_delivery_margin,
    seller_commission,
    seller_commission_no_vat,
  	b2c_white_commission_no_vat,
    trx_commission_no_vat,
    b2c_white_commission,
    trx_commission,
    co.status,
    delivery_workflow,
    delivery_service,
    platform_id,
    is_intercity,
    is_created,
    is_paid,
    is_confirmed,
    is_performed,
    is_provided,
    is_received,
    is_accepted,
    is_canceled,
    is_voided,
    is_unperformed,
    is_return_performed,
    is_return_delivered,
    is_returned,
    is_unconfirmed,
    co.microcat_id,
    is_new,
    is_delivery_discount,
    items_qty,
    is_cart,
    is_bundle,
    is_original,
    is_mall,
    has_short_video,
    time_to_payment,
  	is_high_price,
    cast(((co.item_price >= 15000) and (co.item_price < 20000)) as boolean) as is_between_15k_and_20k_price,
    cast(((co.item_price >= 10000) and (co.item_price < 15000)) as boolean) as is_between_10k_and_15k_price,
    cast((co.item_price < 10000) as boolean) as is_less_than_10k_price,
    b2c_wo_dbs,
    c2c_return_within_14_days,
    return_within_14_days,
    user_segment_market,
    ------ cкидки
    threefirst_discount,
     bonus_discount,
    bonus_cashback,
    promocode_discount,
    c2c_seller_discount,
    c2c_seller_avito_discount, -- скидка Авито, если субсидии продавца не хватает для бесплатной доставки
    exmail_discount,
    ------ флаг скидки
    is_threefirst_discount,
    is_bonus_discount,
    is_bonus_cashback,
    is_promocode_discount,
    is_c2c_seller_discount,
    is_exmail_discount,
    ------ субсидии
    total_subsidies,
    -------------- subsidies (субсидии c экономией от скидки с2с_seller_discount)
    threefirst_subsidies,
    bonus_subsidies,
    promocode_subsidies_wo_tax,
    promocode_subsidies,
    exmail_subsidies,
    c2c_seller_avito_subsidies, -- доплата Авито, если субсидии продавца не хватает для бесплатной доставки
    -------------- total_subsidies (субсидии без экономии от скидки с2с_seller_discount)
    total_threefirst_subsidies,
    total_exmail_subsidies,
    total_promocode_subsidies_wo_tax,
    total_promocode_subsidies,
    -------------- saved_subsidies
    threefirst_subsidies_saved,
    exmail_subsidies_saved,
    promocode_subsidies_saved,
    ------ привязки в контуре авито
    has_avito_bindings,
    payment_flow,
    ------ метрики OPR и PCR
    co.is_finally_paid,
    co.is_paid_purchase,
    co.purchase_equal_final_purchase,
    co.paylink_not_null,
    co.is_cod,
    purchase_ext,
    case when cast(co.create_date as date) >= cast(onboarding_ended_db as date) then true
     else false
    end as has_opened_delivery_wallet,
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
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
    cl.LocationGroup_id                                          as location_group_id,
    cl.City_Population_Group                                     as population_group,
    cl.Logical_Level                                             as location_level_id,
    --buyer location
    bl.location_id                                               as buyer_location_id,
    case bl.level when 3 then bl.ParentLocation_id else bl.Location_id end as buyer_region_id,
    case bl.level when 3 then bl.Location_id end                           as buyer_city_id,
    bl.LocationGroup_id                                          as buyer_location_group_id,
    bl.City_Population_Group                                     as buyer_population_group,
    bl.Logical_Level                                             as buyer_location_level_id,
    co.in_sale,
    co.has_sbp_bindings,
    case
        when inn_info.inn_status then 'B2C White'
        when coalesce(usm.user_segment, ls.segment) not in ('Private.Seller','Private (Earning).Seller','Private (Earning).Extra Small') then 'B2C Gray'
        else 'C2C'
    end as seller_segment_marketplace,
    co.gross_profit as gp,
    case
    	when co.gross_profit >= 0 then co.gross_profit
    end as gp_pos,
    case
    	when co.gross_profit < 0 then -co.gross_profit
    end as gp_neg,
    case
    	when co.gross_profit >= 0 then co.gross_profit
        when co.gross_profit < 0 then -co.gross_profit
    end as gp_abs,
    coalesce(bfs.segment_id, 4) as buyer_frequency_segmentation_id,
    coalesce(brs.segment_id, 3) as buyer_retention_segmentation_id
from dma.delivery_metric_for_ab co
left join dma.current_logical_categories clc on clc.logcat_id = co.logical_category_id
left join dma.current_microcategories cm on cm.microcat_id = co.microcat_id
left join dma.current_locations as cl on co.warehouse_location_id = cl.location_id
left join dma.current_locations as bl on co.buyer_location_id = bl.location_id
left join /*+jtype(h),distrib(l,a)*/ dma.current_wallet_user as cwu on cwu.user_id = co.buyer_id
left join (
    select
        user_id
        , valid_from
        , coalesce(lead(valid_from) over (partition by user_id order by valid_from), '2030-01-01') as valid_to
        , segment_id
    from dict.buyer_frequency_segmentation
) as bfs on co.buyer_id = bfs.user_id and co.create_date >= bfs.valid_from and co.create_date < bfs.valid_to
left join (
    select
        user_id
        , valid_from
        , coalesce(lead(valid_from) over (partition by user_id order by valid_from), '2030-01-01') as valid_to
        , segment_id
    from dict.buyer_retention_segmentation
) as brs on co.buyer_id = brs.user_id and co.create_date >= brs.valid_from and co.create_date < brs.valid_to
left join /*+jtype(h),distrib(l,a)*/
(
    select
        c.event_date,
        user_id,
        inn_status,
        active_from,
        active_until
    from
        (
        select *,
               coalesce(cast(lead(active_from) over(partition by user_id order by active_from asc) as date) - interval '1' day, cast('2030-01-01' as date)) as active_until -- дата окончания действия этого статуса
        from
            (
                select
                    cast(event_time as date) as active_from,
                    user_id,
                    status as inn_status,
                    row_number() over(partition by user_id, cast(event_time as date) order by event_time desc) as rn
                from
                    dma.verification_statuses
                where 1=1
                    and verification_type = 'INN'
    --                and event_year <= date_trunc('year', date(:last_date)) -- @trino
            ) _
        where rn = 1 --получаем последний за день статус
        ) inn_info
        join dict.calendar c on c.event_date between :first_date and :last_date
        where c.event_date between inn_info.active_from and inn_info.active_until
) inn_info on co.seller_id = inn_info.user_id and cast(co.status_date as date) = inn_info.event_date
 left join /*+jtype(h),distrib(l,a)*/ DMA.user_segment_market usm
      on co.seller_id = usm.user_id
      and co.logical_category_id = usm.logical_category_id
      and cast(co.status_date as date) = usm.event_date
      and usm.reason_code is not null
      and usm.event_date between :first_date and :last_date
      -- and usm.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
 left join /*+jtype(h),distrib(l,a)*/ dict.segmentation_ranks ls on co.logical_category_id = ls.logical_category_id and is_default
where true 
    and date(co.status_date) between date(:first_date) and date(:last_date)
    -- and status_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
