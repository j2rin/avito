with am_client_day as (
select user_id,
       active_from_date,
       active_to_date,
       (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
       user_group_id
from DMA.am_client_day_versioned
)
 select
 	t.trigger_date,
    case
        when trigger_type = 'messenger' then 'messenger'
        when trigger_type=  'link_regexp' or trigger_type = 'link_message' then 'link'
        when trigger_type like '%phone%' then 'phone'
        when trigger_type like '%email%' or trigger_type like '%Email%' then 'email'
        when trigger_type like '%nick%' then 'nick'
    ELSE 'other'
    end as trigger,
 	t.chat_id,
	chat_role,
    from_user_id as user_id,
    item_id,
    contains_phone,
    is_abandoned_chat,
    is_copy_after_trigger,
    responses_with_phone_1d,
    is_first_message,
	t. microcat_id,
	-- Dimensions -----------------------------------------------------------------------------------------------------
    cm.vertical_id,
	cm.category_id,
	cm.subcategory_id,
	cm.logical_category_id,
	cm.Param1_microcat_id                                        as param1_id,
	cm.Param2_microcat_id                                        as param2_id,
	cm.Param3_microcat_id                                        as param3_id,
	cm.Param4_microcat_id                                        as param4_id,
	coalesce(acd.is_asd, False)                                       as is_asd,
    acd.user_group_id                                            as asd_user_group_id,
    coalesce(usm.user_segment, ls.segment)                            as user_segment_market
from DMA.messenger_online_fraud_observations t
left join DMA.current_microcategories cm
		on cm.microcat_id = t.microcat_id
left join dict.segmentation_ranks ls
		on ls.logical_category_id = cm.logical_category_id
		and ls.is_default
left join am_client_day acd
		on t.from_user_id = acd.user_id
		and t.trigger_date between acd.active_from_date and acd.active_to_date
left join DMA.user_segment_market usm
        on t.from_user_id = usm.user_id
        and cm.logical_category_id = usm.logical_category_id
        and cast(t.trigger_date as timestamp) = usm.event_date
        and usm.reason_code is not null
        and usm.event_date between :first_date and :last_date
        -- and usm.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
where cast(trigger_date as date) between :first_date and :last_date
    --and trigger_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
