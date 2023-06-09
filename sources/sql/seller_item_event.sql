with am_client_day as (
    select user_id,
           active_from_date,
           active_to_date,
           (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
           user_group_id
    from DMA.am_client_day_versioned
    where active_from_date <= :last_date
        and active_to_date >= :first_date
),
smartphone_buyout_screens as (
  select sbs.internal_item_id as item_id
       , event_date
       , max (case when eid = 6519 or (eid = 6703 and banner_type = 'invitation') then true else false end) as smartphone_buyout_seen_invitation_cd
       , max (case when eid = 6520 or (eid = 6698 and banner_type = 'invitation') then true else false end) as smartphone_buyout_entered_flow_cd
       , max (case when eid = 6769 and buyout_screen_type = 'request' then true else false end) as smartphone_buyout_request_screen_cd
       , max (case when eid = 6769 and buyout_screen_type = 'final' then true else false end) as smartphone_buyout_request_completed_cd
       , max (case when eid = 6519 or (eid = 6703 and banner_type = 'invitation') then event_date end) as smartphone_buyout_seen_invitation_date
    from DMA.smartphone_buyout_screens as sbs
    where event_date::date between :first_date and :last_date
    group by 1,2
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
    t.start_time::date                                       as start_date,
    t.last_activation_time::date                             as last_activation_date,
    null as user_segment,
    -- Dimensions -----------------------------------------------------------------------------------------------------
    nvl(lc.vertical_id, cm.vertical_id)                       as vertical_id,
    nvl(lc.logical_category_id, cm.logical_category_id)       as logical_category_id,
    cm.category_id,
    cm.subcategory_id,
    cm.Param1_microcat_id                                     as param1_id,
    cm.Param2_microcat_id                                     as param2_id,
    cm.Param3_microcat_id                                     as param3_id,
    cm.Param4_microcat_id                                     as param4_id,
    decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id) as region_id,
    decode(cl.level, 3, cl.Location_id, null)                 as city_id,
    cl.LocationGroup_id                                       as location_group_id,
    cl.City_Population_Group                                  as population_group,
    cl.Logical_Level                                          as location_level_id,
    nvl(acd.is_asd, False)                                    as is_asd,
    acd.user_group_id                                         as asd_user_group_id,
    nvl(usm.user_segment, ls.segment)                         as user_segment_market,
    t.location_id,
    t.microcat_id,
    lc.logical_param1_id,
    lc.logical_param2_id,
    ifnull(t.condition_id, 0)                                as condition_id,
    t.is_delivery_active,
    smartphone_buyout_seen_invitation_cd,
    smartphone_buyout_entered_flow_cd,
    smartphone_buyout_request_screen_cd,
    smartphone_buyout_request_completed_cd,
    smartphone_buyout_seen_invitation_date
from  DMA.o_seller_item_event t
left join /*+jtype(h),distrib(l,a)*/ (
    select infmquery_id, logcat_id
    from infomodel.current_infmquery_category
    where infmquery_id in (
        select distinct infmquery_id
        from dma.o_seller_item_event
        where event_date::date between :first_date and :last_date
            and infmquery_id is not null
    )
) ic
    on ic.infmquery_id = t.infmquery_id
left join dma.current_logical_categories lc on lc.logcat_id = ic.logcat_id
left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cm on cm.microcat_id = t.microcat_id
left join /*+jtype(h),distrib(l,b)*/ dict.segmentation_ranks ls on ls.logical_category_id = nvl(lc.logical_category_id, cm.logical_category_id) and ls.is_default
left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations cl on cl.Location_id = t.location_id
left join /*+distrib(l,a)*/ dma.user_segment_market usm on t.user_id = usm.user_id and nvl(lc.logical_category_id, cm.logical_category_id) = usm.logical_category_id
                                                                and t.event_date interpolate previous value usm.converting_date
left join /*+jtype(h),distrib(l,a)*/ am_client_day acd on t.user_id = acd.user_id and t.event_date between acd.active_from_date and acd.active_to_date
left join /*+jtype(h),distrib(l,a)*/ smartphone_buyout_screens as sbs on t.item_id = sbs.item_id and t.event_date = sbs.event_date
where t.event_date between :first_date and :last_date
