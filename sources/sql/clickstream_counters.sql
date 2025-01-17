select 
    cs.event_date,
    cs.eid,
    cs.platform_id,
    cs.cookie_id,
    cs.user_id,
    cs.microcat_id,
    cs.location_id,
    cs.search_correction_action,
    cs.search_correction_method,
    cs.source,
    cs.placement,
    cs.page_type,
    cs.banner_id,
    cs.action_type,
    coalesce(cs.app_call_mic_access, false) as app_call_mic_access,
    cs.from_block,
    cs.ext_profile_is_using,
    cs.profile_type,
    cs.profile_id,
    cs.target_fps,
    cs.actual_fps,
    cs.fps_threshold,
    cs.fps_drawdown,
    coalesce(cs.is_delivery_available, false) as is_delivery_available,
    cs.event_count,
    cm.vertical_id,
    cm.logical_category_id,
    cm.category_id,
    cm.subcategory_id,
    cm.Param1_microcat_id                                      as param1_id,
    cm.Param2_microcat_id                                      as param2_id,
    cm.Param3_microcat_id                                      as param3_id,
    cm.Param4_microcat_id                                      as param4_id,
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
    cl.LocationGroup_id                                        as location_group_id,
    cl.City_Population_Group                                   as population_group,
    cl.Logical_Level                                           as location_level_id,
    cs.vas_path,
    case
       when cs.from_page like 'vertical_category%' then 'vertical_category'
       when cs.from_page like 'vertical_promo%' then 'vertical_promo'
       when cs.from_page like 'vertical_filter%' then 'vertical_filter'
       when cs.from_page='VerticalMain' then 'vertical_filter'
       when cs.from_page='0' and cs.eid in (4920,4921,4954) then 'vertical_filter'
       when cs.from_page like 'recentSearch%' then 'recentSearch'
       else cs.from_page end as from_page,
    item_id,
    source_click_page,
    from_big_endian_64(xxhash64(cast(coalesce(orderid_string, '') as varbinary))) as orderid_string,
    orderid,
    msg_is_pin,
    from_big_endian_64(xxhash64(cast(coalesce(msg_chat, '') as varbinary))) as msg_chat
from DMA.click_stream_counters cs
left join DMA.current_microcategories cm on cm.microcat_id = cs.microcat_id
left join DMA.current_locations cl on cl.location_id = cs.location_id
where cast(cs.event_date as date) between :first_date and :last_date
    --and event_month between date_trunc('month', :first_date) and date_trunc('month', :last_date) -- @trino
