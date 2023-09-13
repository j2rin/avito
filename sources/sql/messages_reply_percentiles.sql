with am_client_day as (
select user_id,
       active_from_date,
       active_to_date,
       (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
       user_group_id
from DMA.am_client_day_versioned
)
 select
    t.event_date,
    from_user_id,
 	platform_id,
 	chat_role,
 	messages,
 	messages_50,
    messages_75,
    messages_90,
    messages_95, 
	-- Dimensions -----------------------------------------------------------------------------------------------------
    lc.vertical_id,
	lc.logical_category_id,
	coalesce(acd.is_asd, False)                                       as is_asd,
    acd.user_group_id                                            as asd_user_group_id
from dma.messenger_answer_percentiles t
left join am_client_day acd
		on t.from_user_id = acd.user_id
		and cast(t.event_date as date) between acd.active_from_date and acd.active_to_date
left join DMA.current_logical_categories lc on lc.logcat_id = t.logical_category_id and level_id=2
where cast(event_date as date) between :first_date and :last_date
