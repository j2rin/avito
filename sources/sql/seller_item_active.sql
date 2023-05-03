with /*+ENABLE_WITH_CLAUSE_MATERIALIZATION */
sia_users as (
    select distinct user_id as user_id
    from dma.o_seller_item_active
    where event_date::date between :first_date::date and :last_date::date
        and user_id is not null
)
select /*+syntactic_join*/
    ss.event_date,
    ss.user_id,
    ss.item_id,
    ss.platform_id,
    ss.start_time,
    ss.start_time::date as start_date,
    ss.last_activation_time,
    ss.last_activation_time::date as last_activation_date,
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
    nvl(ig.Location_id, ss.location_id)                       as location_id,
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
    null::varchar as user_segment,
    ig.has_address_id,
    ig.CoordinatesLatitude,
    ig.CoordinatesLongitude,
    ig.address_id,
    ig.min_kind_level,
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
    -- Dimensions -----------------------------------------------------------------------------------------------------
    nvl(lc.vertical_id, cm.vertical_id)                       as vertical_id,
    nvl(lc.logical_category_id, cm.logical_category_id)       as logical_category_id,
    cm.category_id                                            as category_id,
    cm.subcategory_id                                         as subcategory_id,
    cm.Param1_microcat_id                                     as param1_id,
    cm.Param2_microcat_id                                     as param2_id,
    cm.Param3_microcat_id                                     as param3_id,
    cm.Param4_microcat_id                                     as param4_id,
    decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id) as region_id,
    decode(cl.level, 3, cl.Location_id, null)                 as city_id,
    cl.LocationGroup_id                                       as location_group_id,
    cl.City_Population_Group                                  as population_group,
    cl.Logical_Level                                          as location_level_id,
    nvl(asd.is_asd, False)                                    as is_asd,
    nvl(asd.user_group_id, 8383)                              as asd_user_group_id, -- By default is SS group - 8383
    COALESCE(usm.user_segment, ls.segment)                         as user_segment_market,
    lc.logical_param1_id,
    lc.logical_param2_id,
    ifnull(ss.condition_id, 0)                                as condition_id,
    ss.is_item_cpa,
    ss.is_user_cpa,
    ss.cpaaction_type,
    ir.reputation_class,
    round(10^round(log(ss.price),1)) as price_rounded

from DMA.o_seller_item_active ss

left join /*+jtype(h),distrib(l,a)*/ (
    select infmquery_id, logcat_id
    from infomodel.current_infmquery_category
    where infmquery_id in (
        select distinct infmquery_id
        from dma.o_seller_item_active
        where event_date::date between :first_date and :last_date
            and infmquery_id is not null
    )
) ic
    on ic.infmquery_id = ss.infmquery_id

left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cm on cm.microcat_id = ss.microcat_id
left join dma.current_logical_categories lc on lc.logcat_id = ic.logcat_id
left join /*+jtype(h),distrib(l,b)*/ dict.segmentation_ranks ls
    on ls.logical_category_id = nvl(lc.logical_category_id, cm.logical_category_id)
    and ls.is_default


left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations cl on cl.Location_id = ss.location_id

left join /*+jtype(h),distrib(l,r)*/ (
    select
        usm.user_id,
        usm.logical_category_id,
        usm.user_segment,
        c.event_date
    from (
        select
            user_id,
            logical_category_id,
            user_segment,
            converting_date as from_date,
            lead(converting_date, 1, '20990101') over(partition by user_id, logical_category_id order by converting_date) as to_date
        from DMA.user_segment_market
        where true
            and user_id in (select user_id from sia_users)
            and converting_date <= :last_date::date
    ) usm
    join dict.calendar c on c.event_date between :first_date::date and :last_date::date
    where c.event_date >= usm.from_date and c.event_date < usm.to_date
        and usm.to_date >= :first_date::date
) usm
    on  ss.user_id = usm.user_id
    and ss.event_date = usm.event_date
    and COALESCE(lc.logical_category_id, cm.logical_category_id) = usm.logical_category_id


left join /*+distrib(l,a)*/ dma.item_geo_information ig
    on ig.user_id = ss.user_id
    and ig.event_date = ss.event_date
    and ig.item_id = ss.item_id
    and ig.event_date between :first_date::date and :last_date::date

left join /*+distrib(l,a)*/ (
   select
        asd.user_id,
        (asd.personal_manager_team is not null and asd.user_is_asd_recognised) as is_asd,
        asd.user_group_id as user_group_id,
        c.event_date
    from DMA.am_client_day_versioned asd
    join dict.calendar c on c.event_date between :first_date::date and :last_date::date
    where c.event_date between asd.active_to_date and asd.active_to_date
        and asd.active_from_date <= :last_date::date
        and asd.active_to_date >= :first_date::date
        and asd.user_id in (select user_id from sia_users)
) asd
    on ss.user_id = asd.user_id
    and ss.event_date::date = asd.event_date

left join /*+distrib(l,r)*/ (
    select
        ci.user_id,
        idd.item_id,
        idd.event_date,
        idd.subsidy_index
    from DMA.item_day_delivery idd
    join dma.current_item ci on ci.item_id = idd.item_id
    where idd.event_date between :first_date::date and :last_date::date
) idd
    on  ss.user_id = idd.user_id
    and ss.item_id = idd.item_id
    and ss.event_date = idd.event_date

left join /*+distrib(l,a)*/ dma.jobs_vacancies_duplicates_daily jvdd
    on jvdd.user_id = ss.user_id
    and jvdd.item_id = ss.item_id
    and jvdd.event_date = ss.event_date
    and jvdd.event_date between :first_date::date and :last_date::date

left join /*+distrib(l,r)*/ (
    select
        ci.user_id,
        pld.item_id,
        pld.event_date::date as event_date,
        count(*) as count_services_price_list
    from dma.price_list_day pld
    join dma.current_item ci on ci.item_id = pld.item_id
    where not pld.stoimost is null
        and pld.event_date between :first_date::date and :last_date::date
    group by 1, 2, 3
) ipl
    on ipl.user_id = ss.user_id
    and ipl.item_id = ss.item_id
    and ipl.event_date = ss.event_date

left join /*+distrib(l,r)*/ (
    select
        ci.user_id,
        sic.item_id,
        sic.event_date
    from dma.services_active_items_calendar sic
    join dma.current_item ci on ci.item_id = sic.item_id
    where sic.event_date between :first_date::date and :last_date::date
) sic
    on sic.user_id = ss.user_id
    and sic.item_id = ss.item_id
    and sic.event_date = ss.event_date

left join /*+distrib(l,r)*/ (
    select
        r.user_id, r.item_id, c.event_date, reputation_class
    from (
        select
            user_id,
            item_id,
            reputation_class,
            from_date,
            lead(from_date, 1, '20990101') over(partition by item_id order by from_date) as to_date
        from (
            select
                user_id,
                item_id,
                event_timestamp::date as from_date,
                argmax_agg(event_timestamp, reputation_class) as reputation_class
            from DMA.click_stream_item_reputation
            where event_timestamp::date <= :last_date
            group by 1, 2, 3
        ) r
    ) r
    join dict.calendar c on c.event_date between :first_date::date and :last_date::date
    where c.event_date >= r.from_date and c.event_date < r.to_date
        and r.to_date >= :first_date::date
) ir
    on  ss.user_id = ir.user_id
    and ss.item_id = ir.item_id
    and ss.event_date = ir.event_date

where (ss.is_user_test is null or ss.is_user_test is false)
    and ss.event_date between :first_date and :last_date
