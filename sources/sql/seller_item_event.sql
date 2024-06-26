with am_client_day as (
    select user_id,
           active_from_date,
           active_to_date,
           (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
           user_group_id
    from DMA.am_client_day_versioned
    where active_from_date <= :last_date
        and active_to_date >= :first_date
)

select
    t.event_date,
    t.user_id,
    t.item_id,
    t.platform_id,
    t.start_time,
    t.last_activation_time,
    t.is_dead,
    t.is_marketplace,
    t.activation_type,
    t.is_item_start,
    t.is_after_ttl,
    t.moder_flags,
    t.manual_moderation,
    t.edits_started_by_src,
    t.edits_by_src,
    t.edits_started,
    t.edits,
    t.edits_description,
    t.edits_title,
    t.edits_price,
    t.edits_photo,
    t.edits_address,
    t.close_status_id,
    t.close_reason_id,
    t.lf_amount_net,
    cast(t.start_time as date)                                       as start_date,
    cast(t.last_activation_time as date)                             as last_activation_date,
    null as user_segment,
    -- Dimensions -----------------------------------------------------------------------------------------------------
    coalesce(lc.vertical_id, cm.vertical_id)                       as vertical_id,
    coalesce(lc.logical_category_id, cm.logical_category_id)       as logical_category_id,
    cm.category_id,
    cm.subcategory_id,
    cm.Param1_microcat_id                                     as param1_id,
    cm.Param2_microcat_id                                     as param2_id,
    cm.Param3_microcat_id                                     as param3_id,
    cm.Param4_microcat_id                                     as param4_id,
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
    cl.LocationGroup_id                                       as location_group_id,
    cl.City_Population_Group                                  as population_group,
    cl.Logical_Level                                          as location_level_id,
    coalesce(acd.is_asd, False)                                    as is_asd,
    acd.user_group_id                                         as asd_user_group_id,
    coalesce(usm.user_segment, ls.segment)                         as user_segment_market,
    t.location_id,
    t.microcat_id,
    lc.logical_param1_id,
    lc.logical_param2_id,
    coalesce(t.condition_id, 0)                                as condition_id,
    t.is_delivery_active,
    from_big_endian_64(xxhash64(
        to_big_endian_64(cast(round(exp(round(ln(abs(coalesce(t.price, 0)) + 1), 1))) as bigint)) ||
        to_big_endian_64(coalesce(t.user_id, 0)) ||
        to_big_endian_64(coalesce(t.microcat_id, 0)) ||
        to_big_endian_64(coalesce(t.profession_id, 0))
    )) as user_microcat_price,
    fs.user_id is not null as is_federal_seller
from  DMA.o_seller_item_event t
left join /*+jtype(h),distrib(l,a)*/ (
    select infmquery_id, logcat_id
    from infomodel.current_infmquery_category
    where infmquery_id in (
        select distinct infmquery_id
        from dma.o_seller_item_event
        where cast(event_date as date) between :first_date and :last_date
            and infmquery_id is not null
            -- and event_year between date_trunc('year', date(:first_date)) and date_trunc('year', date(:last_date)) -- @trino
    )
) ic
    on ic.infmquery_id = t.infmquery_id
left join dma.current_logical_categories lc on lc.logcat_id = ic.logcat_id
left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cm on cm.microcat_id = t.microcat_id
left join /*+jtype(h),distrib(l,b)*/ dict.segmentation_ranks ls on ls.logical_category_id = coalesce(lc.logical_category_id, cm.logical_category_id) and ls.is_default
left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations cl on cl.Location_id = t.location_id
left join /*+distrib(l,a)*/ dma.user_segment_market usm
    on t.user_id = usm.user_id
    and coalesce(lc.logical_category_id, cm.logical_category_id) = usm.logical_category_id
    and t.event_date = usm.event_date
    and usm.reason_code is not null
    and usm.event_date between :first_date and :last_date
    -- and usm.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
left join /*+jtype(h),distrib(l,a)*/ am_client_day acd on t.user_id = acd.user_id and t.event_date between acd.active_from_date and acd.active_to_date
left join /*+jtype(h),distrib(l,a)*/ DMA.federal_sellers fs
    on t.user_id = fs.user_id
        and fs.federal_achieved=1
        and t.event_date = fs.event_date
    -- and fs.event_year between date_trunc('year', date(:first_date)) and date_trunc('year', date(:last_date)) -- @trino

where t.event_date between :first_date and :last_date
    -- and t.event_year between date_trunc('year', date(:first_date)) and date_trunc('year', date(:last_date)) -- @trino
