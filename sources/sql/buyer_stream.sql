with /*+ENABLE_WITH_CLAUSE_MATERIALIZATION */
bs_users as (
    select distinct item_user_id as user_id
    from dma.buyer_stream
    where cast(event_date as date) between :first_date and :last_date
        and item_user_id is not null
),
bs_items as (
    select distinct item_id
    from dma.buyer_stream
    where cast(event_date as date) between :first_date and :last_date
        and item_id is not null
)
select
    ss.platform_id,
    ss.event_date,
    ss.cookie_id,
    ss.user_id,
    ss.session_no,
    ss.item_id,
    ss.item_user_id,
    ss.eid,
    ss.x,
    ss.query_id,
    -- для того, чтобы метрики с query одинаково считать на buyer_stream и clickstream_sparse
    case when ss.query_id is not null then 'q' else '' end as q,
    coalesce(ss.item_count,0) as item_count,
    coalesce(ss.base_item_count,0) as base_item_count,
    ss.page_no,
    coalesce(ss.rec_position, 0) as rec_position,
    ss.from_page,
    ss.item_vas_flags,
    ss.phone_view_source,
    ss.item_x_type % 2 as item_x_type,
    ss.x_eid,
    case when ss.x_eid is not null then coalesce(ss.search_flags,0) end as search_flags,
    coalesce(ss.item_flags,  0) as item_flags,
    coalesce(ss.other_flags, 0) as other_flags,
    ss.x_from_page,
    ss.search_sort,
    ss.search_query_type,
    ss.item_serp_flags,
    ss.is_human_dev                                              as is_human,
    cast(ss.search_radius as varchar)                                    as search_radius,
    ss.district_count,
    ss.metro_count,
    from_big_endian_64(xxhash64(to_big_endian_64(ss.item_id) || to_big_endian_64(ss.x) || to_big_endian_64(ss.eid))) as item_x,
    ss.location_id,
    ss.microcat_id,
    ss.item_engines,
    from_big_endian_64(xxhash64(to_big_endian_64(ss.location_id) || to_big_endian_64(ss.session_no) || to_big_endian_64(ss.microcat_id))) as location_session_microcat,
    acc.SFAccount_Type as SFAccount_Type,
    case when ss.eid in (401, 2574, 2732) then 1 when ss.eid = 402 then -1 end as favorites_net,
    case when ss.eid in (451) then 1 when ss.eid = 452 then -1 end as comparisons_net,
    -- Dimensions -----------------------------------------------------------------------------------------------------
    coalesce(lc.vertical_id, cm.vertical_id)                     as vertical_id,
    coalesce(lc.logical_category_id, cm.logical_category_id)     as logical_category_id,
    cm.category_id                                               as category_id,
    cm.subcategory_id                                            as subcategory_id,
    cm.Param1_microcat_id                                        as param1_id,
    cm.Param2_microcat_id                                        as param2_id,
    cm.Param3_microcat_id                                        as param3_id,
    cm.Param4_microcat_id                                        as param4_id,
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
    cl.LocationGroup_id                                          as location_group_id,
    cl.City_Population_Group                                     as population_group,
    cl.Logical_Level                                             as location_level_id,
    ss.rec_engine_id,
    en.Name                                                      as engine,
    cmx.vertical_id                                              as x_vertical_id,
    cmx.logical_category_id                                      as x_logical_category_id,
    cmx.category_id                                              as x_category_id,
    cmx.subcategory_id                                           as x_subcategory_id,
    cmx.Param1_microcat_id                                       as x_param1_id,
    cmx.Param2_microcat_id                                       as x_param2_id,
    cmx.Param3_microcat_id                                       as x_param3_id,
    cmx.Param4_microcat_id                                       as x_param4_id,
    case clx.level when 3 then clx.ParentLocation_id else clx.Location_id end as x_region_id,
    case clx.level when 3 then clx.Location_id end                            as x_city_id,
    clx.LocationGroup_id                                         as x_location_group_id,
    clx.City_Population_Group                                    as x_population_group,
    clx.Logical_Level                                            as x_location_level_id,
    case
       when (bitwise_and(item_vas_flags, bitwise_left_shift(1, 12)) > 0 or bitwise_and(item_vas_flags, bitwise_left_shift(1, 13)) > 0) then 2
       when (bitwise_and(item_vas_flags, bitwise_left_shift(1, 14)) > 0 or bitwise_and(item_vas_flags, bitwise_left_shift(1, 15)) > 0) then 5
       when (bitwise_and(item_vas_flags, bitwise_left_shift(1, 16)) > 0 or bitwise_and(item_vas_flags, bitwise_left_shift(1, 17)) > 0) then 10
       else 1
    end                                                          as vas_power,
    case
        when (bitwise_and(ss.item_flags, bitwise_left_shift(1, 18)) > 0) then 5 -- Новое
        when (bitwise_and(ss.item_flags, bitwise_left_shift(1, 19)) > 0) then 1 -- Б/у
        when (bitwise_and(ss.item_flags, bitwise_left_shift(1, 20)) > 0) then 2 -- Битый
        when (bitwise_and(ss.item_flags, bitwise_left_shift(1, 21)) > 0) then 4 -- Не битый
        else 0 --Undefined
    end                                                          as condition_id,
    cast(bitwise_and(case when ss.x_eid is not null then coalesce(ss.search_flags, 0) end, 16) > 0 as int) as onmap,
    bitwise_and(bitwise_left_shift(case when ss.x_eid is not null then coalesce(ss.search_flags, 0) end, 10), 0xFFFFF) as search_features,
    ubb.track_id is not null as new_user_btc,
    coalesce(asd.is_asd,false) is_asd,
    -- По дефолту ставим SS сегмент - 8383
    coalesce(asd.asd_user_group_id,8383) as asd_user_group_id,
    coalesce(usm.user_segment_market, ls.segment) as user_segment_market,
    ss.item_rnk,
    ss.boost_class_id,
    3 AS multiplier_3,
    5 AS multiplier_5,
    10 AS multiplier_10,
    case (bitwise_and(ss.item_flags, (bitwise_left_shift(1, 32) + bitwise_left_shift(1, 33)))) / power(2, 32) when 1 then 'medium' when 2 then 'low' when 3 then 'high' end as reputation_class,
    case when ((bitwise_and(ss.search_flags, bitwise_left_shift(1, 39)) > 0) and (bitwise_and(ss.search_flags, bitwise_left_shift(1, 40)) = 0) and (bitwise_and(ss.search_flags, bitwise_left_shift(1, 41)) = 0) and (bitwise_and(ss.search_flags, bitwise_left_shift(1, 42)) = 0)) then 1
    	 when ((bitwise_and(ss.search_flags, bitwise_left_shift(1, 39)) = 0) and (bitwise_and(ss.search_flags, bitwise_left_shift(1, 40)) > 0) and (bitwise_and(ss.search_flags, bitwise_left_shift(1, 41)) = 0) and (bitwise_and(ss.search_flags, bitwise_left_shift(1, 42)) = 0)) then 2
         when ((bitwise_and(ss.search_flags, bitwise_left_shift(1, 39)) > 0) and (bitwise_and(ss.search_flags, bitwise_left_shift(1, 40)) > 0) and (bitwise_and(ss.search_flags, bitwise_left_shift(1, 41)) = 0) and (bitwise_and(ss.search_flags, bitwise_left_shift(1, 42)) = 0)) then 3
         when ((bitwise_and(ss.search_flags, bitwise_left_shift(1, 39)) = 0) and (bitwise_and(ss.search_flags, bitwise_left_shift(1, 40)) = 0) and (bitwise_and(ss.search_flags, bitwise_left_shift(1, 41)) > 0) and (bitwise_and(ss.search_flags, bitwise_left_shift(1, 42)) = 0)) then 4
         when ((bitwise_and(ss.search_flags, bitwise_left_shift(1, 39)) > 0) and (bitwise_and(ss.search_flags, bitwise_left_shift(1, 40)) = 0) and (bitwise_and(ss.search_flags, bitwise_left_shift(1, 41)) > 0) and (bitwise_and(ss.search_flags, bitwise_left_shift(1, 42)) = 0)) then 5
         end as s_view_mode,
    cast((bitwise_and(ss.item_flags, bitwise_left_shift(1, 28)) > 0) and (bitwise_and(ss.item_flags, bitwise_left_shift(1, 17)) > 0) as int) as is_item_with_video_cpa,
    date_diff('hour', ial.sort_time, ss.event_date) as item_age_hours,
    date_diff('hour', ial.start_time, ss.event_date) as item_start_hours,
    pg.price_group,
    from_big_endian_64(xxhash64(
        to_big_endian_64(cast(round(exp(round(ln(ial.price), 1))) as int)) ||
        to_big_endian_64(ss.item_user_id) ||
        to_big_endian_64(ss.microcat_id) ||
        to_big_endian_64(ss.x) ||
        to_big_endian_64(ss.eid)
    )) as seller_microcat_price_x,
    cast(bitwise_and(ss.item_flags, bitwise_left_shift(1, 34)) > 0 and bitwise_and(ss.item_flags, bitwise_left_shift(1, 16)) > 0 as int) as b2c_wo_dbs,
    cast(bitwise_and(ss.item_flags, bitwise_left_shift(1, 35)) > 0 and bitwise_and(ss.item_flags, bitwise_left_shift(1, 16)) > 0 as int) as c2c_return_within_14_days,
    cast((bitwise_and(ss.item_flags, bitwise_left_shift(1, 34)) > 0 or bitwise_and(ss.item_flags, bitwise_left_shift(1, 35)) > 0) and bitwise_and(ss.item_flags, bitwise_left_shift(1, 16)) > 0 as int) as return_within_14_days
from DMA.buyer_stream ss
left join /*+jtype(h),distrib(l,a)*/ DDS.S_EngineRecommendation_Name en ON en.EngineRecommendation_id = ss.rec_engine_id
left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cmx on cmx.microcat_id = ss.x_microcat_id
left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cm on cm.microcat_id = ss.microcat_id
left join /*+jtype(h),distrib(l,a)*/ (
        select infmquery_id, logcat_id
        from infomodel.current_infmquery_category
        where infmquery_id in (
            select distinct infmquery_id
            from dma.o_seller_item_active
            where cast(event_date as date) between :first_date and :last_date
                and infmquery_id is not null
        )
    ) ic on ic.infmquery_id = ss.infmquery_id
left join dma.current_logical_categories lc on lc.logcat_id = ic.logcat_id
left join /*+jtype(h),distrib(l,a)*/ dict.segmentation_ranks ls on cm.logical_category_id = ls.logical_category_id and is_default
left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations clx on clx.Location_id = ss.x_location_id
left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations cl on cl.Location_id = ss.location_id

left join /*+jtype(fm),distrib(l,a)*/ (
    select first_action_track_id as track_id, first_action_event_no as event_no
    from DMA.user_btc_birthday
    where cast(first_action_event_date as date) between :first_date and :last_date
        and action_type = 'btc'
) ubb on ubb.track_id = ss.track_id and ubb.event_no = ss.event_no

left join /*+jtype(h),distrib(l,a)*/ (
    select
        usm.user_id,
        usm.logical_category_id,
        usm.user_segment as user_segment_market,
        c.event_date
    from (
        select
            user_id,
            logical_category_id,
            user_segment,
            converting_date as from_date,
            lead(converting_date, 1, cast('2099-01-01' as date)) over(partition by user_id, logical_category_id order by converting_date) as to_date
        from DMA.user_segment_market
        where user_id in (select user_id from bs_users)
            and converting_date <= :last_date
    ) usm
    join dict.calendar c on c.event_date between :first_date and :last_date
    where c.event_date >= usm.from_date and c.event_date < usm.to_date
        and usm.to_date >= :first_date
) usm on ss.item_user_id = usm.user_id and cm.logical_category_id = usm.logical_category_id and cast(ss.event_date as date) = usm.event_date

left join /*+jtype(h),distrib(l,a)*/ (
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
        and asd.user_id in (select user_id from bs_users)
) asd on ss.item_user_id = asd.user_id and cast(ss.event_date as date) between asd.active_from_date and asd.active_to_date

left join /*+jtype(h),distrib(l,b)*/ (
    select
        user_id,
        cast(max(COALESCE(SFAccount_Type, SFTopParentAccount_type)) as varchar(128)) as SFAccount_Type
    from DMA.salesforce_usermapping
    where COALESCE(SFAccount_Type, SFTopParentAccount_type) is not null
        and user_id in (select user_id from bs_users)
    group by user_id
) acc on acc.User_id = ss.item_user_id

left join /*+jtype(h),distrib(l,a)*/ (
    select
        item_id,
        from_date,
        to_date,
        sort_time,
        start_time,
  		price
    from dma.item_attr_log
    where item_id in (
            select item_id from bs_items
        )
        and from_date <= :last_date
        and to_date >= :first_date
) ial
    on ial.item_id = ss.item_id
    and cast(ss.event_date as date) between ial.from_date and ial.to_date
left join /*+jtype(h),distrib(l,a)*/ dict.current_price_groups pg on cm.logical_category_id=pg.logical_category_id and ial.price>=pg.min_price and ial.price< pg.max_price     
    

where cast(ss.event_date as date) between :first_date and :last_date
