with /*+ENABLE_WITH_CLAUSE_MATERIALIZATION */
from_users as (
    select distinct from_user_id
    from dma.messenger_messages
    where cast(event_date as date) between :first_date and :last_date
        and from_user_id is not null
)
select
 	cast(mm.event_date as date),
 	mm.eventtype_id,
 	mm.chat_id,
	mm.platform_id,
    mm.from_user_id as user_id,
	0 as zero,
    mm.from_cookie_id,
    mm.message_id,
    mm.chat_item_id as item_id,
    mm.is_item_owner,
    mm.chat_type,
    mm.chat_subtype,
    mm.is_first_message,
	mm.chat_item_microcat_id as microcat_id,
	mm.chat_item_location_id as location_id,
	case
           when cb.chat_id is not null then true
		   else false
    end as is_chatbot_chat,
    case 
        when mm.from_user_id is null then null
        when cut.user_id is not null then true
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
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
	cl.LocationGroup_id                                          as location_group_id,
	cl.City_Population_Group                                     as population_group,
	cl.Logical_Level                                             as location_level_id,
	coalesce(acd.is_asd, False)                                       as is_asd,
    acd.user_group_id                                            as asd_user_group_id,
    coalesce(usm.user_segment, ls.segment)                            as user_segment_market
from DMA.messenger_messages mm
left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cm on cm.microcat_id = mm.chat_item_microcat_id
left join /*+jtype(h),distrib(l,a)*/ dict.segmentation_ranks ls on ls.logical_category_id = cm.logical_category_id and ls.is_default
left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations cl ON cl.Location_id = mm.chat_item_location_id
left join (
    select
        user_id,
        active_from_date,
        active_to_date,
        (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
        user_group_id
    from DMA.am_client_day_versioned
    where active_from_date <= :last_date
        and active_to_date >= :first_date
) acd
		on mm.from_user_id = acd.user_id
		and cast(mm.event_date as date) between acd.active_from_date and acd.active_to_date

left join /*distrib(l,a)*/ (
    select user_id
    from dma."current_user"
    where isTest
        and user_id in (select from_user_id from from_users)
) cut
    on cut.user_id = mm.from_user_id

left join /*distrib(l,a)*/ (
    select
        usm.user_id,
        usm.logical_category_id,
        usm.user_segment,
        usm.from_date,
        usm.to_date
    from (
        select
            user_id,
            logical_category_id,
            user_segment,
            converting_date as from_date,
            lead(converting_date, 1, '20990101') over(partition by user_id, logical_category_id order by converting_date) as to_date
        from DMA.user_segment_market
        where true
            and user_id in (select from_user_id from from_users)
            and converting_date <= :last_date
    ) usm
    where usm.to_date >= :first_date
) usm
    on  mm.from_user_id = usm.user_id
    and cast(mm.event_date as date) >= usm.from_date and cast(mm.event_date as date) < usm.to_date
    and cm.logical_category_id = usm.logical_category_id

left join /*distrib(l,a)*/ (
    select
        chat_id,
        start_flow_time,
        coalesce(end_flow_time, cast('9999-12-31' as timestamp)) as _end_flow_time
    from DMA.messenger_chat_flow_report
    where cast(start_flow_time as date) <= :last_date
        and _end_flow_time >= :first_date
) cb
    on cb.chat_id = mm.chat_id
    and mm.event_date >=  cb.start_flow_time
    and mm.event_date <= cb._end_flow_time

where cast(mm.event_date as date) between :first_date and :last_date
    and not mm.is_spam
    and not mm.is_blocked
    and not mm.is_deleted
    and not mm.is_additional
