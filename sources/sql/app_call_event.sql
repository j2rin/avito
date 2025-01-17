select
    ap.event_date,
    ap.cookie_id,
    ap.user_id,
    ap.platform_id,
    ap.item_id,
    ap.microcat_id,
    ap.location_id,
    ap.is_iac_only,
    ap.appcall_item_show_buttons,
    ap.appcall_item_gallery_show_buttons,
    ap.appcall_messenger_chat_menu_show_buttons,
    ap.appcall_messenger_chat_long_answer_show_buttons,
    ap.appcall_item_click_phone,
    ap.appcall_item_gallery_click_phone,
    ap.appcall_messenger_chat_menu_click_phone,
    ap.appcall_messenger_chat_long_answer_click_phones,
    ap.appcall_item_click_inapp,
    ap.appcall_item_gallery_click_inapp,
    ap.appcall_messenger_chat_menu_click_inapp,
    ap.appcall_messenger_chat_long_answer_click_inapp,
    ap.appcall_caller_end_call_rating,
    -- Dimensions -----------------------------------------------------------------------------------------------------
    cm.vertical_id                                               as vertical_id,
    cm.logical_category_id                                       as logical_category_id,
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
    cl.Logical_Level                                             as location_level_id
from DMA.o_app_call_event ap
left join DMA.current_microcategories cm on cm.microcat_id = ap.microcat_id
left join DMA.current_locations cl on cl.Location_id = ap.location_id
where cast(event_date as date) between :first_date and :last_date
-- and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
