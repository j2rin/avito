with /*+ENABLE_WITH_CLAUSE_MATERIALIZATION */
user_matching as (
    select
        autoteka_user_id,
        date_from,
  		lead(date_from, 1, cast('2099-01-01' as date)) over (partition by autoteka_user_id order by date_from) lead_date_from,
        max(cookie_id) as cookie_id,
        max(user_id) as user_id
    from dma.autoteka_avito_user_matching
    where 1=1 
    --and date_year is not null --@trino
    group by 1, 2
),
autoteka as (
select
    track_id,
    event_no,
    event_date,
    cast(event_date as date) as dt,
    cookie_id,
    user_id,
    additionalcookie_id,
    autotekauser_id,
    is_authorized,
    searchkey,
    searchtype,
    item_id,
    platenumber,
    vin,
    autoteka_platform_id,
    autotekaorder_id,
    reports_count,
    amount,
    amount_net,
    payment_method,
    user_created_at,
    is_new_user,
    funnel_stage_id,
    utm_campaign,
    utm_source,
    utm_medium,
    platform_id,
    autoteka_cookie_id,
    is_pro,
    utm_content,
    utm_term,
    'standalone' as source,
  	from_big_endian_64(xxhash64(cast(cast(autotekauser_id as varchar) || 'standalone' as varbinary))) as autoteka_user_hash,
  	from_big_endian_64(xxhash64(cast(cast(autotekaorder_id as varchar) || 'standalone' as varbinary))) autoteka_order_hash,
    0 as fake_user_id
from dma.autoteka_stream 
where cast(event_date as date) between :first_date and :last_date
--and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
union all
select
    track_id,
    event_no,
    event_date,
    cast(event_date as date) as dt,
    cookie_id,
    user_id,
    null as additionalcookie_id,
    null as autotekauser_id,
    is_authorized,
    null as searchkey,
    coalesce(search_type, 1) as searchtype,
    item_id,
    null platenumber,
    null vin,
    null autoteka_platform_id,
    null as autotekaorder_id,
    reports_count,
    amount,
    amount_net,
    null payment_method,
    null user_created_at,
    is_new_user,
    funnel_stage_id,
    null utm_campaign,
    null utm_source,
    null utm_medium,
    platform_id,
    null as autoteka_cookie_id,
    is_pro,
    null utm_content,
    null utm_term,
    'avito' as source,
  	from_big_endian_64(xxhash64(cast(cast(user_id as varchar) || 'avito' as varbinary))) as autoteka_user_hash,
  	from_big_endian_64(xxhash64(cast(cast(order_items_id as varchar) || 'avito' as varbinary))) as autoteka_order_hash,
    0 as fake_user_id
from dma.autoteka_on_avito_stream_and_payments
where cast(event_date as date) between :first_date and :last_date
--and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
)
select
    autoteka.track_id,
    autoteka.event_no,
    autoteka.event_date,
    case when autoteka.source = 'standalone' then coalesce(autoteka.cookie_id, ut.cookie_id) else autoteka.cookie_id end as cookie_id,
    case when autoteka.source = 'standalone' then coalesce(ut2.user_id, autoteka.user_id) else autoteka.user_id end as user_id,
    autoteka.additionalcookie_id,
    autoteka.autotekauser_id,
    autoteka.is_authorized,
    autoteka.searchkey,
    autoteka.searchtype,
    autoteka.item_id,
    autoteka.platenumber,
    autoteka.vin,
    autoteka.autoteka_platform_id,
    autoteka.autotekaorder_id,
    autoteka.reports_count,
    autoteka.amount,
    autoteka.amount_net,
    autoteka.payment_method,
    autoteka.user_created_at,
    autoteka.is_new_user,
    autoteka.funnel_stage_id,
    autoteka.utm_campaign,
    autoteka.utm_source,
    autoteka.utm_medium,
    autoteka.platform_id,
    autoteka.autoteka_cookie_id,
    autoteka.is_pro,
    autoteka.utm_content,
    autoteka.utm_term,
    autoteka.source,
    autoteka.fake_user_id,
    autoteka.autoteka_user_hash,
    autoteka.autoteka_order_hash,
    coalesce(mc.logical_category_id, 24144500001) as logical_category_id,
    coalesce(mc.vertical_id, 500012) as vertical_id
from autoteka
left join dma.current_item ci 
    on autoteka.item_id = ci.item_id
left join /*+jtype(h),distrib(l,a)*/ dma.current_microcategories mc
    on mc.microcat_id = ci.microcat_id
    and mc.vertical='Transport'
left join user_matching ut on ut.autoteka_user_id = autoteka.autotekauser_id and autoteka.dt >= ut.date_from and autoteka.dt < ut.lead_date_from
left join (
    select autoteka_user_id, user_id, date_from, lead_date_from
    from user_matching
    where user_id is not null
) ut2 on ut2.autoteka_user_id = autoteka.autotekauser_id and autoteka.dt >= ut2.date_from and autoteka.dt < ut2.lead_date_from;
