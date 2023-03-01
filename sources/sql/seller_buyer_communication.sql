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
 select
 	sbc.chat_id,
 	sbc.user_id,
 	sbc.to_user_id as buyer_id,
 	discount_send_date,
	platform_id,
    answer_platform,
    answer_time::date,
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
	nvl(acd.is_asd, False)                                       as is_asd,
    acd.user_group_id                                            as asd_user_group_id,
    nvl(usm.user_segment, ls.segment)                            as user_segment_market
from DMA.messenger_seller_buyer_communication sbc
left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cm
		on cm.microcat_id = sbc.microcat_id
left join /*+jtype(h),distrib(l,b)*/ dict.segmentation_ranks ls
		on ls.logical_category_id = cm.logical_category_id
		and ls.is_default
left join am_client_day acd
		on sbc.user_id = acd.user_id
		and sbc.discount_send_date between acd.active_from_date and acd.active_to_date
left join usm
        on sbc.user_id = usm.user_id
        and cm.logical_category_id = usm.logical_category_id
		and sbc.discount_send_date::timestamp >= converting_date and sbc.discount_send_date::timestamp < next_converting_date
where (
           sbc.discount_send_date::date between :first_date and :last_date
        or sbc.answer_time::date between :first_date and :last_date
    )

