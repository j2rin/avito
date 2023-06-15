with calls_scores as 
(
    select 
        call_id
        ,call_type
        ,is_target_call as is_target
        ,case                       -- МОЖЕТ СТОИТ ДОБАВИТЬ not_andswered как в чатах?
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
        end as type
    from
        dma.target_call
    where
        call_time::date between :first_date and :last_date
)
, asd as 
(
    select 
        user_id,
        active_from_date,
        active_to_date,
        personal_manager_team is not null and user_is_asd_recognised as is_asd,
        user_group_id
    from 
        DMA.am_client_day_versioned
    where 
        active_to_date::date >= :first_date
)
, usm as
(
    select *
    from 
        (
            select
                user_id
                ,logical_category_id
                ,user_segment
                ,converting_date
                ,lead(converting_date, 1, '20990101') over(partition by user_id, logical_category_id order by converting_date) as next_converting_date
            from 
                DMA.user_segment_market 
        ) as a
    where 
        converting_date <= :last_date -- убираем изменения после расчетного периода
        and next_converting_date >= :first_date -- убираем изменения до расчетного периода
)
, gsm_calls as
(
    with mathcing as 
    (
        select 
            ancall_id
            ,item_id
            ,buyer_id
            ,cookie_id
            ,platform_id
        from 
            DMA.anonymous_calls_contacts_matching
        where 
            call_date between :first_date and :last_date
            and matching_type = 'Any'
    )
    , gsm_with_matching as 
    (
        select
            a.UPPCallAcceptedAt::date as event_date
            ,'gsm' as communication
            ,a.UPPClient as communication_type
            ,'' as communication_subtype
            ,a.UPPCallId as communication_id
            ,b.buyer_id
            ,a.User_id as seller_id
            ,a.UPPCallAcceptedAt::date as reply_date
            ,coalesce(a.Item_id, b.item_id) as item_id
            ,coalesce(a.UPPCallDuration, 0) as call_duration
            ,coalesce(a.UPPTalkDuration, 0) as talk_duration
            ,coalesce(a.UPPTalkDuration, 0) > 0 as is_answered
            ,b.platform_id as platform_id
            ,null::int as second_platform_id
            ,b.cookie_id as buyer_cookie_id
            ,null::int as seller_cookie_id
        from 
            dma.upp_calls as a 
            left join mathcing as b on a.UPPCallId = b.ancall_id
        where 
            UPPCallAcceptedAt::date between :first_date and :last_date
            and a.UPPClient in ('anonymous-number-4', 'calltracking')
    )
    select
        a.*
        ,b.microcat_id
        ,b.category_id
        ,b.location_id
        ,c.vertical_id
        ,c.vertical
        ,c.logical_category_id
        ,c.logical_category
        ,c.subcategory_id
        ,c.Param1_microcat_id as param1_id
        ,c.Param2_microcat_id as param2_id
        ,c.Param3_microcat_id as param3_id
        ,c.Param4_microcat_id as param4_id
        ,d.is_target
        ,d.type
        ,decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id)    as region_id
	    ,decode(cl.level, 3, cl.Location_id, null)                    as city_id
	    ,cl.LocationGroup_id                                          as location_group_id
	    ,cl.City_Population_Group                                     as population_group
	    ,cl.Logical_Level                                             as location_level_id
    from 
        gsm_with_matching as a
        left join dma.current_item as b using(Item_id)
        left join dma.current_microcategories as c using(microcat_id)
        left join calls_scores as d on d.call_type = 'ct' and d.call_id = a.communication_id
        left join dma.current_locations as cl using(location_id)
)
, iac_calls as 
(
    select
        a.AppCallStart::date as event_date
        ,'iac' as communication
        ,'' as communication_type
        ,'' as communication_subtype
        ,a.AppCall_id as communication_id
        ,AppCallCaller_id as buyer_id -- правильно ли???
        ,AppCallReciever_id as seller_id -- правильно ли???
        ,a.AppCallStart::date as reply_date 
        ,a.Item_id as item_id
        ,coalesce(a.CallDuration, 0) as call_duration
        ,coalesce(a.TalkDuration, 0) as talk_duration
        ,coalesce(a.TalkDuration, 0) > 0 as is_answered
        ,CallerPlatform as platform_id
        ,RecieverPlatform as second_platform_id
        ,CallerDevice as buyer_cookie_id
        ,RecieverDevice as seller_cookie_id
        ,a.Microcat_id
        ,c.category_id
        ,a.location_id
        ,c.vertical_id
        ,c.vertical
        ,c.logical_category_id
        ,c.logical_category
        ,c.subcategory_id
        ,c.Param1_microcat_id as param1_id
        ,c.Param2_microcat_id as param2_id
        ,c.Param3_microcat_id as param3_id
        ,c.Param4_microcat_id as param4_id
        ,d.is_target
        ,d.type
        ,decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id)    as region_id
	    ,decode(cl.level, 3, cl.Location_id, null)                    as city_id
	    ,cl.LocationGroup_id                                          as location_group_id
	    ,cl.City_Population_Group                                     as population_group
	    ,cl.Logical_Level                                             as location_level_id
    from 
        DMA.app_calls as a
        left join dma.current_microcategories as c using(microcat_id)
        left join calls_scores as d on d.call_type = 'iac' and d.call_id = a.AppCall_id
        left join dma.current_locations as cl using(location_id)
    where 
        AppCallStart::date between :first_date and :last_date
)
, chats as 
(
    with chat_scores as (
        select 
            chat_id
            ,item_id
            ,class
        from 
            dma.messenger_chat_scores
        where 
            first_message_event_date::date >= :first_date -- норм ли?
    )
    select
        first_message_event_date::date as event_date
        ,'msg' as communication
        ,chat_type as communication_type
        ,chat_subtype as communication_subtype
        ,chr.chat_id as communication_id
        ,first_message_user_id as buyer_id -- сделал первое сообщение и не является владельцем айтема (всегда баер)
        ,user_id as seller_id -- владелец объявления
        ,reply_time::date as reply_date
        ,chr.item_id as item_id
        ,0 as call_duration
        ,0 as talk_duration
        ,with_reply as is_answered
        ,platform_id
        ,reply_platform_id as second_platform_id
        ,first_message_cookie_id as buyer_cookie_id
        ,null::int as seller_cookie_id
        ,chr.microcat_id
        ,chr.category_id
        ,chr.item_location_id as location_id
        ,cm.vertical_id
        ,cm.vertical
        ,cm.logical_category_id
        ,cm.logical_category
        ,cm.subcategory_id
        ,cm.Param1_microcat_id as param1_id 
        ,cm.Param2_microcat_id as param2_id
        ,cm.Param3_microcat_id as param3_id
        ,cm.Param4_microcat_id as param4_id
        ,case when cs.class in (3,4,5) or chr.orders>=1 then true else false end as is_target
        ,case
            when class in (3,4,5) or orders>=1 then 'target'
            when class in (1,2,6,7,8) and with_reply = true then 'preliminary'
            when is_spam = true then 'trash'
            when with_reply = false then 'not_answered'
        end as type
        ,decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id)      as region_id
	    ,decode(cl.level, 3, cl.Location_id, null)                      as city_id
	    ,cl.LocationGroup_id                                            as location_group_id
	    ,cl.City_Population_Group                                       as population_group
	    ,cl.Logical_Level                                               as location_level_id
    from DMA.messenger_chat_report chr
    left join chat_scores as cs using(chat_id, item_id)
    left join DMA.current_microcategories cm on cm.microcat_id = chr.microcat_id
    left join DMA.current_locations cl on cl.Location_id = chr.item_location_id
    where true
       -- and not is_spam
        and not is_bad_cookie
        and not is_blocked
        and not is_deleted
        and messages > 0 -- не берем первый этап воронки (создание чата) в этом расчете
        and (
                first_message_event_date::date between :first_date and :last_date
            or  reply_time::date between :first_date and :last_date -- зачем такие чаты брать в расчет?
        )
)
select 
    a.*
    -- ,nvl(asd.is_asd, False) as is_asd
    -- ,asd.user_group_id as asd_user_group_id
    -- ,nvl(usm.user_segment, ls.segment) as user_segment_market
from 
    (
        select *
        from gsm_calls
        union all 
        select *
        from iac_calls
        union all 
        select *
        from chats
    ) as a 
    -- left join asd on a.seller_id = asd.user_id 
    --                 and a.event_date between asd.active_from_date and asd.active_to_date
    -- left join dict.segmentation_ranks ls on ls.logical_category_id = a.logical_category_id 
    --                 and ls.is_default
    -- left join usm on a.seller_id = usm.user_id
    --                 and a.logical_category_id = usm.logical_category_id
    --                 and a.event_date >= usm.converting_date and a.event_date < next_converting_date