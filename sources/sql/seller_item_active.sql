with /*+ENABLE_WITH_CLAUSE_MATERIALIZATION */
sia_users as (
    select distinct user_id as user_id
    from dma.o_seller_item_active
    where cast(event_date as date) between :first_date and :last_date
        and user_id is not null
)
select /*+syntactic_join*/
    ss.event_date,
    ss.user_id,
    ss.item_id,
    ss.platform_id,
    ss.start_time,
    cast(ss.start_time as date) as start_date,
    ss.last_activation_time,
    cast(ss.last_activation_time as date) as last_activation_date,
    ss.is_active,
    ss.is_marketplace,
    ss.is_message_forbidden,
    ss.microcat_id,
    ss.status_id,
    ss.photo_count,
    ss.description_word_count,
    ss.contacts,
    ss.contacts_msg,
    ss.contacts_ph,
    ss.favs_added,
    ss.favs_removed,
    ss.activations_count,
    ss.activations_after_ttl_count,
    ss.item_views,
    ss.vas_mask,
    coalesce(ig.Location_id, ss.location_id)                       as location_id,
    ig.CoordinatesIsManual,
    ig.metro_id,
    ig.address_length,
    ig.has_address,
    ig.has_metro,
    ig.has_street,
    ig.has_building,
    ig.no_city,
    ig.wrong_order,
    ig.location_distance,
    ig.metro_distance,
    cast(null as varchar) as user_segment,
    ig.has_address_id,
    ig.CoordinatesLatitude,
    ig.CoordinatesLongitude,
    ig.address_id,
    ig.min_kind_level,
    ig.addresses_count,
    ss.is_delivery_available,
    ss.is_delivery_active,
    ss.delivery_clicks,
    ss.delivery_contacts,
    ss.seller_rating,
    ss.has_short_video,
    idd.subsidy_index,
    jvdd.is_original,
    jvdd.duplicates_count,
    ipl.count_services_price_list,
    sic.item_id is not null as is_item_calendar,
    ipl.quality_price_list,
    aed.levenshtein_strict,
    aed.levenshtein_light,
    aed.jaccard_strict,
    aed.jaccard_light,
    
    -- Dimensions -----------------------------------------------------------------------------------------------------
    coalesce(lc.vertical_id, cm.vertical_id)                       as vertical_id,
    coalesce(lc.logical_category_id, cm.logical_category_id)       as logical_category_id,
    cm.category_id                                            as category_id,
    cm.subcategory_id                                         as subcategory_id,
    cm.Param1_microcat_id                                     as param1_id,
    cm.Param2_microcat_id                                     as param2_id,
    cm.Param3_microcat_id                                     as param3_id,
    cm.Param4_microcat_id                                     as param4_id,
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
    cl.LocationGroup_id                                       as location_group_id,
    cl.City_Population_Group                                  as population_group,
    cl.Logical_Level                                          as location_level_id,
    coalesce(asd.is_asd, False)                                    as is_asd,
    coalesce(asd.asd_user_group_id, 8383)                          as asd_user_group_id, -- By default is SS group - 8383
    COALESCE(usm.user_segment, ls.segment)                    as user_segment_market,
    lc.logical_param1_id,
    lc.logical_param2_id,
    coalesce(ss.condition_id, 0)                                as condition_id,
    ss.is_item_cpa,
    ss.is_user_cpa,
    ss.cpaaction_type,
    case ss.reputation_class_id when 1 then 'low' when 2 then 'medium' when 3 then 'high' end as reputation_class,
    from_big_endian_64(xxhash64(
        to_big_endian_64(cast(round(exp(round(ln(abs(coalesce(ss.price, 0)) + 1), 1))) as bigint)) ||
        to_big_endian_64(coalesce(ss.user_id, 0)) ||
        to_big_endian_64(coalesce(ss.microcat_id, 0)) ||
        to_big_endian_64(coalesce(ss.profession_id, 0))
    )) as user_microcat_price,
    COALESCE(ss.group_id, ss.item_id) as seller_group,
    ss.item_rating,
    is_delivery_active_regular,
    is_delivery_available_regular,
    delivery_flow,
    ss.is_premium,
    fs.user_id is not null as is_federal_seller

from DMA.o_seller_item_active ss

left join /*+jtype(h),distrib(l,a)*/ (
    select infmquery_id, logcat_id
    from infomodel.current_infmquery_category
    where infmquery_id in (
        select distinct infmquery_id
        from dma.o_seller_item_active
        where cast(event_date as date) between :first_date and :last_date
            and infmquery_id is not null
    )
) ic
    on ic.infmquery_id = ss.infmquery_id

left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cm on cm.microcat_id = ss.microcat_id
left join dma.current_logical_categories lc on lc.logcat_id = ic.logcat_id
left join /*+jtype(h),distrib(l,b)*/ dict.segmentation_ranks ls
    on ls.logical_category_id = coalesce(lc.logical_category_id, cm.logical_category_id)
    and ls.is_default


left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations cl on cl.Location_id = ss.location_id

left join /*+jtype(h),distrib(l,r)*/ DMA.user_segment_market usm
    on  ss.user_id = usm.user_id
    and ss.event_date = usm.event_date
    and COALESCE(lc.logical_category_id, cm.logical_category_id) = usm.logical_category_id
    and usm.reason_code is not null
    and usm.event_date between :first_date and :last_date
    -- and usm.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino

left join /*+distrib(l,a)*/ dma.item_geo_information ig
    on ig.user_id = ss.user_id
    and ig.event_date = ss.event_date
    and ig.item_id = ss.item_id
    and ig.event_date between :first_date and :last_date

left join /*+distrib(l,a)*/ (
    select
        asd.user_id,
        (asd.personal_manager_team is not null and asd.user_is_asd_recognised) as is_asd,
        asd.user_group_id as asd_user_group_id,
        asd.active_from_date,
        asd.active_to_date
    from DMA.am_client_day_versioned asd
    where true
        and asd.active_from_date <= :last_date
        and asd.active_to_date >= :first_date
        and asd.user_id in (select user_id from sia_users)
) asd
    on ss.user_id = asd.user_id
    and cast(ss.event_date as date) between asd.active_from_date and asd.active_to_date

left join /*+distrib(l,r)*/ (
    select
        ci.user_id,
        idd.item_id,
        idd.event_date,
        idd.subsidy_index
    from dma.current_item ci
    join DMA.item_day_delivery idd on ci.item_id = idd.item_id
    where idd.event_date between :first_date and :last_date
) idd
    on  ss.user_id = idd.user_id
    and ss.item_id = idd.item_id
    and ss.event_date = idd.event_date

left join /*+distrib(l,a)*/ dma.jobs_vacancies_duplicates_daily jvdd
    on jvdd.user_id = ss.user_id
    and jvdd.item_id = ss.item_id
    and jvdd.event_date = ss.event_date
    -- and jvdd.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino

left join /*+distrib(l,r)*/ (
    select 
            user_id,
            pld.item_id,
            cast(pld.event_date as date) as event_date,
            services as count_services_price_list,
            quality_price_list
    from dma.current_item ci
    join dma.item_metric_price_list_day pld on ci.item_id = pld.item_id
    where pld.event_date between :first_date and :last_date
    -- and pld.event_year is not null -- @trino
) ipl
    on ipl.user_id = ss.user_id
    and ipl.item_id = ss.item_id
    and ipl.event_date = ss.event_date

left join /*+distrib(l,r)*/ (
    select
        ci.user_id,
        sic.item_id,
        sic.event_date
    from dma.current_item ci
    join dma.services_active_items_calendar sic on ci.item_id = sic.item_id
    where sic.event_date between :first_date and :last_date
        -- and sic.event_year is not null -- @trino
) sic
    on sic.user_id = ss.user_id
    and sic.item_id = ss.item_id
    and sic.event_date = ss.event_date

left join /*+jtype(h),distrib(l,a)*/ DMA.federal_sellers fs
    on ss.user_id = fs.user_id
        and fs.federal_achieved=1
        and ss.event_date = fs.event_date
    -- and fs.event_year between date_trunc('year', date(:first_date)) and date_trunc('year', date(:last_date)) -- @trino

left join /*+distrib(l,r)*/
dma.autodescribe_edit_distance aed
	on aed.item_id = ss.item_id
    -- and aed.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino

where (ss.is_user_test is null or ss.is_user_test = false)
    and ss.event_date between :first_date and :last_date

