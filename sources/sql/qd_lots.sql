select
    created_at,
    terminated_at,
    user_id,
    mp_request_id,
    mp_lot_id,
    seller_choice_at,
    seller_choice_applied_to_offers_at,
    platform,
    entrypoint,
    status_id,
    listing_price_group,
    has_offer,
    has_buyout,
    buyout_amount,
    charge,
    bt_revenue,
    count_bid,
    case when seller_choice_at is not null and status_id !=9 then 1 else 0 end as is_seller_choice_of_winner, 
    case when seller_choice_applied_to_offers_at is not null and status_id !=9 then 1 else 0 end as is_any_choice_of_winner,
    case when status_id = 9 then 1 else 0 end as is_declined_offers,
--- Dimensions ----------------------------------------------------- GOD, SAVE MY SOUL (source: dma.metrics_dimension_value)
    500012              as vertical_id,         --Transport
    24144500001         as logical_category_id, --Transport.UsedCars
    12					as category_id,			--Транспорт
    43                  as subcategory_id,      --Автомобили
    3250006             as param1_id,           --С пробегом
    case when platform = 'ios'      then 4
         when platform = 'android'  then 3
         when platform = 'mav'      then 2
         when platform = 'desktop'  then 1
         else null end                                           as platform_id,
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id
from dma.qd_auto_report_lots l
left join DMA.current_locations cl on cl.location_id = l.location_id
where cast(created_at as date) between :first_date and :last_date
    or cast(terminated_at as date) between :first_date and :last_date