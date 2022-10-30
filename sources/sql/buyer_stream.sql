with /*+ENABLE_WITH_CLAUSE_MATERIALIZATION */
bs_users as (
    select distinct item_user_id as user_id
    from dma.buyer_stream
    where event_date::date between :first_date::date and :last_date::date
        and item_user_id is not null
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
    NVL(ss.rec_position, 0) as rec_position,
    ss.from_page,
    ss.item_vas_flags,
    ss.phone_view_source,
    ss.item_x_type % 2 as item_x_type,
    ss.x_eid,
    case when ss.x_eid is not null then coalesce(ss.search_flags,0) end as search_flags,
    coalesce(ss.item_flags,0) as item_flags,
    coalesce(ss.other_flags,0) as other_flags,
    ss.x_from_page,
    ss.search_sort,
    ss.search_query_type,
    ss.item_serp_flags,
    ss.is_human_dev                                              as is_human,
    ss.search_radius::varchar                                    as search_radius,
    ss.district_count,
    ss.metro_count,
    hash(ss.item_id, ss.x, ss.eid)                              as item_x,
    ss.location_id,
    ss.microcat_id,
    ss.item_engines,
    hash(ss.location_id, ss.session_no, ss.microcat_id)         as location_session_microcat,
    acc.SFAccount_Type as SFAccount_Type,
    case when ss.eid in (401, 2574, 2732) then 1 when ss.eid = 402 then -1 end as favorites_net,
    case when ss.eid in (451) then 1 when ss.eid = 452 then -1 end as comparisons_net,
    -- Dimensions -----------------------------------------------------------------------------------------------------
    cm.vertical_id                                               as vertical_id,
    cm.logical_category_id                                       as logical_category_id,
    cm.category_id                                               as category_id,
    cm.subcategory_id                                            as subcategory_id,
    cm.Param1_microcat_id                                        as param1_id,
    cm.Param2_microcat_id                                        as param2_id,
    cm.Param3_microcat_id                                        as param3_id,
    cm.Param4_microcat_id                                        as param4_id,
    decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id)    as region_id,
    decode(cl.level, 3, cl.Location_id, null)                    as city_id,
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
    decode(clx.level, 3, clx.ParentLocation_id, clx.Location_id) as x_region_id,
    decode(clx.level, 3, clx.Location_id, null)                  as x_city_id,
    clx.LocationGroup_id                                         as x_location_group_id,
    clx.City_Population_Group                                    as x_population_group,
    clx.Logical_Level                                            as x_location_level_id,
    case
       when (item_vas_flags & (1 << 12) > 0 or item_vas_flags & (1 << 13) > 0) then 2
       when (item_vas_flags & (1 << 14) > 0 or item_vas_flags & (1 << 15) > 0) then 5
       when (item_vas_flags & (1 << 16) > 0 or item_vas_flags & (1 << 17) > 0) then 10
       else 1
    end                                                          as vas_power,
    case
        when (ss.item_flags & (1 << 18) > 0) then 5 -- Новое
        when (ss.item_flags & (1 << 19) > 0) then 1 -- Б/у
        when (ss.item_flags & (1 << 20) > 0) then 2 -- Битый
        when (ss.item_flags & (1 << 21) > 0) then 4 -- Не битый
        else 0 --Undefined
    end                                                          as condition_id,
    ((case when ss.x_eid is not null then coalesce(ss.search_flags, 0) end & 16) > 0)::int as onmap,
    (case when ss.x_eid is not null then coalesce(ss.search_flags, 0) end >> 10) & 0xFFFFF as search_features,
    ubb.track_id is not null as new_user_btc,
    asd.is_asd,
    asd.asd_user_group_id,
    coalesce(usm.user_segment_market, ls.segment) as user_segment_market,
    ss.item_rnk,
    ss.boost_class_id,
    3 AS multiplier_3,
    5 AS multiplier_5,
    10 AS multiplier_10
from DMA.buyer_stream ss
left join /*+jtype(h),distrib(l,a)*/ DDS.S_EngineRecommendation_Name en ON en.EngineRecommendation_id = ss.rec_engine_id
left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cmx on cmx.microcat_id = ss.x_microcat_id
left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cm on cm.microcat_id = ss.microcat_id
left join /*+jtype(h),distrib(l,a)*/ dict.segmentation_ranks ls on cm.logical_category_id = ls.logical_category_id and is_default
left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations clx on clx.Location_id = ss.x_location_id
left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations cl on cl.Location_id = ss.location_id

left join /*+jtype(fm),distrib(l,a)*/ (
    select first_action_track_id as track_id, first_action_event_no as event_no
    from DMA.user_btc_birthday
    where first_action_event_date::date between :first_date::date and :last_date::date
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
            lead(converting_date, 1, '20990101') over(partition by user_id, logical_category_id order by converting_date) as to_date
        from DMA.user_segment_market
        where user_id in (select user_id from bs_users)
            and converting_date <= :last_date::date
    ) usm
    join dict.calendar c on c.event_date between :first_date::date and :last_date::date
    where c.event_date between usm.from_date and usm.to_date
        and usm.to_date >= :first_date::date
) usm on ss.item_user_id = usm.user_id and cm.logical_category_id = usm.logical_category_id and ss.event_date::date = usm.event_date

left join /*+jtype(h),distrib(l,a)*/ (
   select
        asd.user_id,
        (asd.personal_manager_team is not null and asd.user_is_asd_recognised) as is_asd,
        asd.user_group_id as asd_user_group_id,
        c.event_date
    from DMA.am_client_day_versioned asd
    join dict.calendar c on c.event_date between :first_date::date and :last_date::date
    where c.event_date between asd.active_to_date and asd.active_to_date
        and asd.active_from_date <= :last_date::date
        and asd.active_to_date >= :first_date::date
        and asd.user_id in (select user_id from bs_users)
) asd on ss.item_user_id = asd.user_id and ss.event_date::date = asd.event_date

left join /*+jtype(h),distrib(l,b)*/ (
    select
        user_id,
        max(COALESCE(SFAccount_Type, SFTopParentAccount_type))::varchar(128) as SFAccount_Type
    from DMA.salesforce_usermapping
    where COALESCE(SFAccount_Type, SFTopParentAccount_type) is not null
        and user_id in (select user_id from bs_users)
    group by user_id
) acc on acc.User_id = ss.item_user_id

where hash(ss.cookie_id, 123) % 10 = 7
    and ss.event_date::date between :first_date and :last_date
