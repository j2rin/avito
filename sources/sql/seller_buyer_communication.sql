with am_client_day as (
    select user_id,
           active_from_date,
           active_to_date,
           (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
           user_group_id
    from DMA.am_client_day_versioned
    where cast(active_from_date as date) <= :last_date
        and cast(active_to_date as date) >= :first_date
)
 select
 	sbc.chat_id,
 	sbc.user_id,
 	sbc.to_user_id as buyer_id,
 	discount_send_date,
	platform_id,
    answer_platform,
    cast(answer_time as date) as answer_time,
    sbc.answer_buyer as answer,
    coalesce(sbc.is_first_message, false) as first_message,
    special_offers,
    sbc.sbc_source as source,
	sbc.microcat_id,
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
from DMA.messenger_seller_buyer_communication sbc
left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cm
		on cm.microcat_id = sbc.microcat_id
left join /*+jtype(h),distrib(l,b)*/ dict.segmentation_ranks ls
		on ls.logical_category_id = cm.logical_category_id
		and ls.is_default
left join am_client_day acd
		on sbc.user_id = acd.user_id
		and sbc.discount_send_date between acd.active_from_date and acd.active_to_date
left join DMA.user_segment_market usm
        on sbc.user_id = usm.user_id
        and cm.logical_category_id = usm.logical_category_id
		and cast(sbc.discount_send_date as timestamp) = usm.event_date
        and usm.event_date between :first_date and :last_date
        -- and usm.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
where (
           cast(sbc.discount_send_date as date) between :first_date and :last_date
        or cast(sbc.answer_time as date) between :first_date and :last_date
    )
    --and discount_send_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
