
 select /*+direct, syn_join*/
    chr.first_message_event_date::Date,
 	t.chat_id,
 	platform_id,
    first_message_user_id as user_id,
    first_message_cookie_id as cookie_id,
    chr.user_id as seller_id,
    chr.item_id,
	cm.microcat_id,
	cl.location_id,
	case 
		when orders > 0 then 1.0 else class end as class ,
	probability,
	case 
		when orders > 0 then 1 
		else (thirdclass_prob + forthclass_prob+fifthclass_prob)
	end as sum_probability,
	case 
	    when orders > 0 then 1 
	    when class in (3,4,5) then 1
        else 0 
    end as is_target_chat,
-- Dimensions -------------------------------------------------------------------
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
from DMA.messenger_chat_scores t
join DMA.messenger_chat_report chr using (chat_id)
left join /*+jtype(h),distrib(l,a)*/  DMA.current_microcategories cm using (microcat_id)
left join /*+jtype(h),distrib(l,b)*/ dict.segmentation_ranks ls
    on ls.logical_category_id = cm.logical_category_id
    and ls.is_default  
left join DMA.current_locations cl using (Location_id)

left join /*+jtype(h),distrib(l,a)*/ 
    (
    select 
      user_id,
       active_from_date,
       active_to_date,
       (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
       user_group_id
from DMA.am_client_day_versioned
    ) acd on chr.user_id = acd.user_id and chr.first_message_event_date::date between acd.active_from_date and acd.active_to_date
    
left join /*+jtype(h),distrib(l,b)*/ 
    (
    select user_id, logical_category_id, user_segment, converting_date,
        lead(converting_date, 1, '20990101') over(partition by user_id, logical_category_id order by converting_date) as next_converting_date
    from DMA.user_segment_market 
    ) as usm
        on chr.user_id = usm.user_id
        and cm.logical_category_id = usm.logical_category_id
        and chr.first_message_event_date >= converting_date and chr.first_message_event_date < next_converting_date
where t.first_message_event_date::date between :first_date and :last_date