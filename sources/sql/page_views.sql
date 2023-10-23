with
current_infmquery_category as (
    select infmquery_id, logcat_id, microcat_id
    from infomodel.current_infmquery_category
    where infmquery_id in (
        select distinct infmquery_id
        from dma.dau_source
        where cast(event_date as date) between :first_date and :last_date
            and infmquery_id is not null
    )
)
select /*+syntactic_join*/
    cast(src.event_date as date) as event_date,
    src.cookie_id,
    src.user_id,
    src.platform_id,
    ic.microcat_id,
    src.location_id,
    lc.vertical_id,
    lc.logical_category_id,
    lc.logical_param1_id,
    lc.logical_param2_id,
    cm.category_id,
    cm.subcategory_id,
    cm.Param1_microcat_id as param1_id,
    cm.Param2_microcat_id as param2_id,
    cm.Param3_microcat_id as param3_id,
    cm.Param4_microcat_id as param4_id,
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
    cl.LocationGroup_id                                    as location_group_id,
    cl.City_Population_Group                               as population_group,
    cl.Logical_Level                                       as location_level_id,
    src.pv_count                                           as events_count,
    src.iv_count                                           as itemviews_count,
    src.serp_count                                         as serp_count,
    src.btc_count                                          as btc_count,
    src.contact                                            as contact_count,
    from_big_endian_64(xxhash64(to_big_endian_64(coalesce(src.cookie_id, 0)) || to_big_endian_64(date_diff('day', date('2000-01-01'), src.event_date))))                        as cookie_day_hash,
    from_big_endian_64(xxhash64(to_big_endian_64(coalesce(src.cookie_id, 0)) || to_big_endian_64(date_diff('day', date('2000-01-01'), date_trunc('month', src.event_date)))))   as cookie_month_hash,
    from_big_endian_64(xxhash64(to_big_endian_64(coalesce(src.user_id, 0)) || to_big_endian_64(date_diff('day', date('2000-01-01'), src.event_date))))                          as user_day_hash,
    from_big_endian_64(xxhash64(to_big_endian_64(coalesce(src.user_id, 0)) || to_big_endian_64(date_diff('day', date('2000-01-01'), date_trunc('month', src.event_date)))))     as user_month_hash
from dma.dau_source src
left join /*+jtype(h),distrib(l,a)*/ current_infmquery_category ic
    on ic.infmquery_id = src.infmquery_id
left join /*+jtype(h),distrib(l,a)*/ dma.current_logical_categories lc
    on lc.logcat_id = ic.logcat_id
left join  /*+jtype(h),distrib(l,a)*/dma.current_microcategories cm
    on cm.microcat_id = ic.microcat_id
left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations cl
    on cl.Location_id = src.location_id
where src.is_human
    and cast(src.event_date as date) between :first_date and :last_date