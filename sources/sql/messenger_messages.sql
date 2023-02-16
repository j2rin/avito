with am_client_day as (
select user_id,
       active_from_date,
       active_to_date,
       (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
       user_group_id
from DMA.am_client_day_versioned
)
, usm as (
    select user_id, logical_category_id, user_segment, converting_date,
        lead(converting_date, 1, '20990101') over(partition by user_id, logical_category_id order by converting_date) as next_converting_date
    from DMA.user_segment_market
)
, chatbot as (
    select
        chat_id,
        start_flow_time,
        end_flow_time
    from DMA.messenger_chat_flow_report
)
 select
 	mm.event_date::Date,
 	eventtype_id,
 	mm.chat_id,
	platform_id,
    from_user_id as user_id,
	0 as zero,
    from_cookie_id,
    message_id,
    chat_item_id as item_id,
    is_item_owner,
    chat_type,
    chat_subtype,
    is_first_message,
	mm.chat_item_microcat_id as microcat_id,
	mm.chat_item_location_id as location_id,
	case
           when cb.chat_id is not null then true
		   else false
    end as is_chatbot_chat,
    case
        when from_user_id is null then null
        when IsTest=true then true
        else false
    end as IsTest,
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
    nvl(usm.user_segment, ls.segment)                            as user_segment_market
from DMA.messenger_messages mm
left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cm
		on cm.microcat_id = mm.chat_item_microcat_id
left join /*+jtype(h),distrib(l,b)*/ dict.segmentation_ranks ls
		on ls.logical_category_id = cm.logical_category_id
		and ls.is_default
left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations cl
		ON cl.Location_id = mm.chat_item_location_id
left join am_client_day acd
		on mm.from_user_id = acd.user_id
		and mm.event_date::date between acd.active_from_date and acd.active_to_date
left join usm
        on mm.from_user_id = usm.user_id
        and cm.logical_category_id = usm.logical_category_id
        and mm.event_date::timestamp >= converting_date and mm.event_date::timestamp < next_converting_date
left join /*+jtype(h),distrib(l,a)*/ dma.current_user cu
        on cu.user_id = from_user_id
		and isTest = true
left join /*+jtype(h),distrib(l,a)*/ chatbot cb
   on cb.chat_id = mm.chat_id
      and mm.event_date >=  start_flow_time
      and (mm.event_date <= end_flow_time or end_flow_time is null)
where mm.event_date::date between :first_date and :last_date
    and not is_spam
    and not is_blocked
    and not is_deleted
    and not is_additional
