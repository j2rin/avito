with tmp_chats as (
select 
    t.first_message_event_date::date as event_date
    ,t.item_id
    ,first_message_user_id as buyer_id
    ,user_id as seller_id
    ,t.chat_id
    ,null::int as call_id
    ,'messenger' as contact_type
    ,case when class in (3,4,5) or orders>=1 then true else false end as is_target
    ,microcat_id
    ,location_id
    ,platform_id
    ,reply_platform_id
    ,first_message_cookie_id as buyer_cookie_id
    ,case
        when class in (3,4,5) or orders>=1 then 'target'
        when class in (1,2,6,7,8) and with_reply = true then 'preliminary'
        when is_spam = true then 'trash'
        when with_reply = false then 'not_answered'
    end as type,
    ' '||to_char(class)||' ' as tags
from  dma.messenger_chat_report t
left join  dma.messenger_chat_scores cs using (chat_id,item_id)
where t.first_message_event_date::date between :first_date::date  and :last_date::date
)
, tmp_calls as (
select 
    call_time::date as event_date
    ,item_id
    ,buyer_id
    ,seller_id
    ,null::int as chat_id
    ,call_id
    ,call_type as contact_type
    ,is_target_call as is_target
    ,microcat_id
    ,location_id
    ,platform_id
    ,null::int as reply_platform_id
    ,buyer_cookie_id
    ,case  
        when is_target = true then 'target'
        when maplookup(mapjsonextractor(prob_distrib), 'already_sold') >0.5 or maplookup(mapjsonextractor(prob_distrib), 'item_deal_discussion') >0.5
                or maplookup(mapjsonextractor(prob_distrib), 'irrelevant_applicant') >0.5  or maplookup(mapjsonextractor(prob_distrib), 'reject_by_employer') >0.5 
                or maplookup(mapjsonextractor(prob_distrib), 'closed_vacancy') >0.5  or maplookup(mapjsonextractor(prob_distrib), 'applicant_refused') >0.5 
                or maplookup(mapjsonextractor(prob_distrib), 'refused_by_employer') >0.5   or maplookup(mapjsonextractor(prob_distrib), 'failed_agreement') >0.5  
                    or maplookup(mapjsonextractor(prob_distrib), 'call_later_no_meeting') >0.5  
    then 'preliminary'
        when maplookup(mapjsonextractor(prob_distrib), 'spam') >0.5 or maplookup(mapjsonextractor(prob_distrib), 'autoreply') >0.5
            or maplookup(mapjsonextractor(prob_distrib), 'agent_call') >0.5  or maplookup(mapjsonextractor(prob_distrib), 'discrimination') >0.5 
      or maplookup(mapjsonextractor(prob_distrib), 'unclear') >0.5  or maplookup(mapjsonextractor(prob_distrib), 'dispatcher_call') >0.5 
      or maplookup(mapjsonextractor(prob_distrib), 'auto_ru') >0.5  or maplookup(mapjsonextractor(prob_distrib), 'failed_call') >0.5 
      or maplookup(mapjsonextractor(prob_distrib), 'mistake') >0.5  or maplookup(mapjsonextractor(prob_distrib), 'different_number') >0.5 
      or maplookup(mapjsonextractor(prob_distrib), 'discrimination') >0.5   or maplookup(mapjsonextractor(prob_distrib), 'illegal_vacancy') >0.5  
      or maplookup(mapjsonextractor(prob_distrib), 'different_offer') >0.5 
    then 'trash'
    end as type,    
      ' '|| case when first_tag_prob > 0.5 then first_tag else '' end
    ||' '|| case when second_tag_prob > 0.5 then second_tag else '' end
    ||' '|| case when third_tag_prob > 0.5 then third_tag else '' end 
    ||' '|| case when fourth_tag_prob > 0.5 then fourth_tag else '' end 
    ||' '|| case when fifth_tag_prob > 0.5 then fifth_tag else '' end
    ||' ' as tags
from dma.target_call
where call_time::date between :first_date::date  and :last_date::date
)
select 
    event_date
    ,item_id
    ,buyer_id
    ,seller_id
    ,chat_id
    ,call_id
    ,contact_type
    ,is_target
    ,platform_id
    ,reply_platform_id
    ,buyer_cookie_id
    ,cm.microcat_id
    ,cl.location_id
    ,type
    -- Dimensions -------------------------------------------------------------------
    ,cm.vertical_id
	,cm.category_id
	,cm.subcategory_id
	,cm.logical_category_id
	,cm.Param1_microcat_id                                        as param1_id
	,cm.Param2_microcat_id                                        as param2_id
	,cm.Param3_microcat_id                                        as param3_id
	,cm.Param4_microcat_id                                        as param4_id
	,decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id)    as region_id
	,decode(cl.level, 3, cl.Location_id, null)                    as city_id
	,cl.LocationGroup_id                                          as location_group_id
	,cl.City_Population_Group                                     as population_group
	,cl.Logical_Level                                             as location_level_id
	,nvl(acd.is_asd, False)                                       as is_asd
    ,acd.user_group_id                                            as asd_user_group_id
    ,nvl(usm.user_segment, ls.segment)                            as user_segment_market
    ,tags
from (
    select 
        * 
    from tmp_calls
    union all 
    select 
        *
    from tmp_chats
) t 

left join  DMA.current_microcategories cm using (microcat_id)
left join dict.segmentation_ranks ls
    on ls.logical_category_id = cm.logical_category_id
    and ls.is_default  
left join DMA.current_locations cl using (Location_id)

left join
    (
    select 
      user_id,
       active_from_date,
       active_to_date,
       (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
       user_group_id
from DMA.am_client_day_versioned
    ) acd on t.seller_id = acd.user_id and t.event_date::date between acd.active_from_date and acd.active_to_date
    
left join 
    (
    select user_id, logical_category_id, user_segment, converting_date,
        lead(converting_date, 1, '20990101') over(partition by user_id, logical_category_id order by converting_date) as next_converting_date
    from DMA.user_segment_market 
    where converting_date <= :last_date::date
    ) as usm
        on t.seller_id = usm.user_id
        and cm.logical_category_id = usm.logical_category_id
        and t.event_date >= converting_date and t.event_date < next_converting_date
