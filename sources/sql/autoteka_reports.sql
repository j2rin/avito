with /*+ENABLE_WITH_CLAUSE_MATERIALIZATION */
items as (
    select distinct hi.item_id, hi.External_ID as item_ext_id
    from dma.autoteka_report_attributes ar
    join dma_autoteka.report_details rd on rd.report_id = ar.report_id
    join /*+distrib(a,l)*/ dds.H_Item hi on hi.External_ID = rd.avito_item_id
    where autoteka_package_history_created_at::date between :first_date and :last_date
      and autoteka_order_id is not null
),
orders as (
    select distinct ar.autoteka_order_id, report_id
    from dma.autoteka_report_attributes ar
    where autoteka_package_history_created_at::date between :first_date and :last_date
      and autoteka_order_id is not null
),
report_details as (
    select rd.report_id,
           rd.vin,
           rd.mileage,
           rd.year,
           rd.avito_item_id
    from dma_autoteka.report_details rd
    where report_id in (select distinct coalesce(report_id, 0) from orders)
),
stream as (
    select
        autotekaorder_id,
        autotekauser_id,
        autoteka_cookie_id,
        user_id,
        cookie_id,
        is_pro,
        searchtype,
        is_new_user,
        platform_id,
        amount,
        reports_count,
        autoteka_platform_id
    from dma.autoteka_stream
    where funnel_stage_id = 4
      and autotekaorder_id in (select distinct coalesce(autoteka_order_id, 0) from orders)
      and event_date::date between (:first_date::date - 180) and :last_date
),
item_price as (select item_id, actual_date, price from dds.S_Item_Price where item_id in (select item_id from items) and actual_date::date <= :last_date),
item_location as (select item_id, actual_date, location_id from dds.L_Item_Location where item_id in (select item_id from items) and actual_date::date <= :last_date),
item_microcat as (select item_id, actual_date, microcat_id from dds.L_Item_MicroCat where item_id in (select item_id from items) and actual_date::date <= :last_date)
select
    ar.autoteka_package_history_id,
    ar.autoteka_package_history_created_at::date,
    ar.user_id,
    ar.cookie_id,
    ar.autoteka_user_id,
    ar.autoteka_cookie_id,
    ar.autoteka_order_id,
    ih.item_id,
    ar.banner_clicks,
    ar.vin,
    ar.is_pro,
    ar.searchtype,
    ar.reports_count,
    ar.revenue_reports_used,
    ar.is_new_user,
    ar.platform_id,
    ar.autoteka_platform_id,
    decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id)  as region_id,
    decode(cl.level, 3, cl.Location_id, null)  as city_id,
    coalesce(mc.logical_category_id, 24144500001) as logical_category_id,
    coalesce(mc.vertical_id, 500012) as vertical_id,
    case
       when ar.year_range <= 3 then '0-3'
       when ar.year_range >= 4 and ar.year_range <= 7 then '4-7'
       when ar.year_range >= 8 then '8+'
       else 'Undefined'
    end as 'autoteka_car_age_group',
    case
       when p.Price <= 500000 then '0-500K'
       when p.Price > 500000 and  p.Price <= 1000000 then '500K-1M'
       when p.Price > 1000000 then '1M+'
       else 'Undefined'
    end as 'autoteka_car_price_group',
    case
       when ar.mileage <= 100000 then '0-100K'
       when ar.mileage > 100000 and ar.mileage <= 150000 then '100K-150K'
       when ar.mileage > 150000 then '150K+'
       else 'Undefined'
    end as 'autoteka_mileage_group'
from (
    select
        autoteka_package_history_id,
        ara.autoteka_package_history_created_at,
        cas.autotekauser_id as autoteka_user_id,
        cas.user_id,
        cas.cookie_id,
        cas.autoteka_cookie_id,
        ara.autoteka_order_id,
        rd.vin,
        rd.mileage,
        rd.year,
        rd.avito_item_id as item_ext_id,
        is_pro,
        searchtype,
        reports_count,
        is_new_user,
        platform_id,
        autoteka_platform_id,
        year(ara.autoteka_package_history_created_at) - rd.year as year_range,
        ars.banner_clicks,
        amount / reports_count as revenue_reports_used
    from dma.autoteka_report_attributes ara
    join stream cas on cas.autotekaorder_id = ara.autoteka_order_id
    left join (
         select
            autoteka_user_report_id,
            count(*) as banner_clicks
         from dma.autoteka_report_stream
         where event_type='banner_click'
            and event_date::date between :first_date and :last_date
         group by 1
    ) ars on ars.autoteka_user_report_id = ara.autoteka_user_report_id
    left join report_details rd on rd.report_id = ara.report_id
    where autoteka_package_history_created_at::date between :first_date and :last_date
) ar
left join items ih on ih.item_ext_id = ar.item_ext_id
left join item_price p on p.Item_id = ih.Item_id and ar.autoteka_package_history_created_at interpolate previous value p.Actual_date
left join item_location l on l.Item_id = ih.Item_id  and ar.autoteka_package_history_created_at  interpolate previous value l.Actual_date
left join item_microcat m on m.Item_id = ih.Item_id  and ar.autoteka_package_history_created_at  interpolate previous value m.Actual_date
left join dma.current_microcategories mc on  mc.microcat_id = m.Microcat_id and mc.vertical='Transport'
left join dma.current_locations cl on cl.Location_id = l.Location_id
