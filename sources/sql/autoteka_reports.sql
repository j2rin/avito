select
    autoteka_package_history_id,
    cast(autoteka_package_history_created_at as date) as autoteka_package_history_created_at,
    user_id,
    cookie_id,
    autoteka_user_id,
    autoteka_cookie_id,
    autoteka_order_id,
    item_id,
    banner_clicks,
    from_big_endian_64(xxhash64(cast(coalesce(vin, '') as varbinary))) as vin,
    is_pro,
    searchtype,
    reports_count,
    revenue_reports_used,
    is_new_user,
    platform_id,
    autoteka_platform_id,
    region_id,
    city_id,
    logical_category_id,
    vertical_id,
    autoteka_car_age_group,
    autoteka_car_price_group,
    autoteka_mileage_group
from DMA.autoteka_report_parameters
where cast(autoteka_package_history_created_at as date) between :first_date and :last_date
    -- and autoteka_package_history_created_year between date_trunc('year', date(:first_date)) and date_trunc('year', date(:last_date)) -- @trino
