with am_client_day as (
    select user_id,
           active_from_date,
           active_to_date,
           (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
           user_group_id
    from DMA.am_client_day_versioned
    where active_from_date::date <= :last_date
        and active_to_date::date >= :first_date
)
, usm as (
    select user_id, logical_category_id, user_segment, converting_date,
        lead(converting_date, 1, '20990101') over(partition by user_id, logical_category_id order by converting_date) as next_converting_date
    from DMA.user_segment_market
    where converting_date::date <= :last_date
)
, chatbot as (
    select
        chat_id,
        start_flow_time,
        end_flow_time
    from DMA.messenger_chat_flow_report
    where start_flow_time::date <= :last_date
        and end_flow_time::date >= :first_date
)
 select
 	chr.chat_id,
 	first_message_event_date::Date,
	platform_id,
    first_message_user_id,
    first_message_cookie_id,
    chr.item_id,
    chat_type,
    chat_subtype,
    reply_user_id,
    reply_message_bot,
    case
        when cb.chat_id is not null then true else false end as is_chat_bot,
    end_flow_time,
    reply_platform_id,
    with_reply,
    chr.user_id,
    reply_time::date,
    datediff ('minute',first_message_event_date, reply_time) as reply_time_minutes,
    case
        when first_message_event_date::date=reply_time::date then true
        else false
    end as is_one_day_reply,
	chr.microcat_id,
	chr.item_location_id,
	-- Dimensions -----------------------------------------------------------------------------------------------------
    cm.vertical_id,
	cm.category_id,
	cm.subcategory_id,
	cm.logical_category_id,
	cm.Param1_microcat_id                                        as param1_id,
	cm.Param2_microcat_id                                        as param2_id,
	cm.Param3_microcat_id                                        as param3_id,
	cm.Param4_microcat_id                                        as param4_id,
	decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id)    as region_id,
	decode(cl.level, 3, cl.Location_id, null)                    as city_id,
	cl.LocationGroup_id                                          as location_group_id,
	cl.City_Population_Group                                     as population_group,
	cl.Logical_Level                                             as location_level_id,
	nvl(acd.is_asd, False)                                       as is_asd,
    acd.user_group_id                                            as asd_user_group_id,
    nvl(usm.user_segment, ls.segment)                            as user_segment_market,
    0 															 as zero
from DMA.messenger_chat_report chr
left join /*+jtype(h),distrib(l,a)*/ chatbot cb
   on cb.chat_id = chr.chat_id
    and (
            (
                    first_message_event_date >=  start_flow_time
                and (first_message_event_date <= end_flow_time or end_flow_time is null)
            )
        or  (
                    reply_time >=  start_flow_time
                and (reply_time <= end_flow_time  or end_flow_time is null)
            )
    )
left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cm
    on cm.microcat_id = chr.microcat_id
left join /*+jtype(h),distrib(l,b)*/ dict.segmentation_ranks ls
    on ls.logical_category_id = cm.logical_category_id
    and ls.is_default
left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations cl
    ON cl.Location_id = chr.item_location_id
left join am_client_day acd
    on chr.user_id = acd.user_id
    and chr.first_message_event_date::date between acd.active_from_date and acd.active_to_date
left join usm
    on chr.user_id = usm.user_id
    and cm.logical_category_id = usm.logical_category_id
    and chr.first_message_event_date::timestamp >= converting_date and chr.first_message_event_date::timestamp < next_converting_date
where true
    and not is_spam
    and not is_bad_cookie
    and not is_blocked
    and not is_deleted
    and (
            first_message_event_date::date between :first_date and :last_date
        or  reply_time::date between :first_date and :last_date
    )
