select
    status_date,
    create_date,
    status_time,
    platform_id,
    buyer_id,
    is_delivery_paid_new,
    is_delivery_accepted_new,
    seller_id,
    marketplaceorder_id,
    marketplacepurchase_id,
    marketplaceitem_id,
    marketplacepurchase_ext,
    item_id,
    item_price,
    co.status,
    billing_project,
    is_created,
    is_paid,
    is_received,
    is_accepted,
    is_canceled,
    is_returned,
    is_cart,
    is_mall,
    time_to_payment,
    c2c_return_within_14_days,
    ------ привязки в контуре авито
    has_avito_bindings,
    has_sbp_bindings,
    payment_flow,
    case when cast(co.create_date as date) >= cast(onboarding_ended_db as date) then true else false end as has_opened_delivery_wallet,
    co.is_finally_paid,
    co.is_paid_purchase,
    co.purchase_equal_final_purchase,
    co.paylink_not_null,
    co.is_cod,
    co.in_sale,
    clc.vertical_id,
    clc.logical_category_id
from DMA.marketplace_fmp_metric_for_ab co
left join dma.current_logical_categories clc on clc.logcat_id = co.logical_category_id
    left join /*+jtype(h),distrib(l,a)*/ dma.current_wallet_user as cwu on cwu.user_id = co.buyer_id
where true
    and date(co.status_date) between date(:first_date) and date(:last_date)
    -- and status_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
