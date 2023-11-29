with 
-- результаты скоринга звонков
calls_scores as 
(
    select 
        call_id
        ,call_type
        ,is_target_call as is_target
        ,case                       -- МОЖЕТ СТОИТ ДОБАВИТЬ not_andswered как в чатах?
                when is_target = True then 'target'
                when is_preliminary_call = True then 'preliminary'
                when is_trash_call = True then 'trash'
        end as type
        ,case when first_tag_prob > 0.4 then first_tag else 'empty_call' end as tags
    from
        dma.target_call
    where True
        and cast(call_time as date) between :first_date and :last_date
)
-- наличие ASD менеджера у продавца
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
    where True
        and cast(active_to_date as date) >= :first_date
)
-- сегмент продавца
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
    where True
        and converting_date <= :last_date -- убираем изменения после расчетного периода
        and next_converting_date >= :first_date -- убираем изменения до расчетного периода
)
-- звонки через подменные номера
, gsm_calls as
(
    -- мэтчинг звонков через подменные с баерами
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
        where True
            and call_date between :first_date and :last_date
            and matching_type = 'Any'
    )
    -- продавцы, отключившие приветствие от Авито в начале звонка
    , avito_hello_status as
    (
        select 
            cast(event_date as date)
            ,user_id
        from
            DMA.calltracking_user_day
        where True
            and cast(event_date as date) between :first_date and :last_date
            and not ctpromptenabled
    )
    , gsm_with_matching as 
    (
        select
            cast(a.UPPCallAcceptedAt as date) as event_date
            ,'gsm' as communication
            ,a.UPPClient as communication_type
            ,'' as communication_subtype
            ,a.UPPCallId as communication_id
            ,b.buyer_id
            ,a.User_id as seller_id
            ,True as caller_is_buyer
            ,cast(a.UPPCallAcceptedAt as date) as reply_date
            ,0 as reply_time_minutes
            ,coalesce(a.Item_id, b.item_id) as item_id
            ,coalesce(a.UPPCallDuration, 0) as call_duration
            ,coalesce(a.UPPTalkDuration, 0) as talk_duration
            ,UPPLinkedPhone is not null and not UPPCallIsBlocked as is_common_funnel
            ,case
                -- мтс
                when UPPProvider = 1 and c.user_id is null      then talk_duration > 8
                when UPPProvider = 1 and c.user_id is not null  then talk_duration > 6
                -- мтт
                when UPPProvider = 2 and c.user_id is null      then talk_duration > 8
                when UPPProvider = 2 and c.user_id is not null  then talk_duration > 6
                -- билайн
                when UPPProvider = 3 and c.user_id is null      then talk_duration > 3
                when UPPProvider = 3 and c.user_id is not null  then talk_duration > 3
                else talk_duration > 0 
                end as is_answered
            ,b.platform_id as platform_id
            ,cast(null as int) as seller_platform_id
            ,b.cookie_id as buyer_cookie_id
        from 
            dma.upp_calls as a 
            left join mathcing as b on a.UPPCallId = b.ancall_id
            left join avito_hello_status as c on cast(a.UPPCallAcceptedAt as date) = c.event_date
                                            and a.User_id = c.user_id
        where True
            and cast(UPPCallAcceptedAt as date) between :first_date and :last_date
            and a.UPPClient in ('anonymous-number-4', 'calltracking')
    )
    select
        a.*
        ,d.is_target
        ,d.type
        ,d.tags
    from 
        gsm_with_matching as a
        left join calls_scores as d on d.call_type = 'ct' and d.call_id = a.communication_id
)
-- звонки через приложение
, iac_calls as 
(
    select
        cast(a.AppCallStart as date) as event_date
        ,'iac' as communication
        ,AppCallScenario as communication_type
        ,'' as communication_subtype
        ,a.AppCall_id as communication_id
        ,case when CallerIsBuyer then AppCallCaller_id else AppCallReciever_id end as buyer_id
        ,case when CallerIsBuyer then AppCallReciever_id else AppCallCaller_id end as seller_id
        ,CallerIsBuyer as caller_is_buyer -- направление вызова
        ,cast(a.AppCallStart as date) as reply_date
        ,0 as reply_time_minutes
        ,a.Item_id as item_id
        ,coalesce(a.CallDuration, 0) as call_duration
        ,coalesce(a.TalkDuration, 0) as talk_duration
        ,CallerIsBuyer as is_common_funnel
        ,coalesce(a.TalkDuration, 0) > 0 as is_answered
        ,case when CallerIsBuyer then CallerPlatform else RecieverPlatform end as platform_id -- платформа баера
        ,case when CallerIsBuyer then RecieverPlatform else CallerPlatform end as seller_platform_id -- платформа селлера
        ,case when CallerIsBuyer then CallerDevice else RecieverDevice end as buyer_cookie_id
        ,NVL(a.is_video_call,) as is_video_call
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
        ,d.tags
        ,case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id
        ,case cl.level when 3 then cl.Location_id end                           as city_id
	    ,cl.LocationGroup_id                                          as location_group_id
	    ,cl.City_Population_Group                                     as population_group
	    ,cl.Logical_Level                                             as location_level_id
    from 
        DMA.app_calls as a
        left join dma.current_microcategories as c on c.microcat_id = a.microcat_id
        left join calls_scores as d on d.call_type = 'iac' and d.call_id = a.AppCall_id
        left join dma.current_locations as cl on cl.location_id = a.location_id
    where True
        and cast(AppCallStart as date) between :first_date and :last_date
        and AppCallScenario is not null
        and CallerIsBuyer is not null
        and AppCallScenario not in ('demo', 'messenger_chat_long_answer', 'messenger_empty_chat', 'support')
        and (AppCallResult is null or AppCallResult not in ('gsm_fallback')) -- безуспешно перенаправленные из gsm в iac и отправленные обратно в gsm
)
-- чаты
, chats as 
(
    -- результаты скоринга чатов
    with chat_scores as (
        select 
            chat_id
            ,item_id
            ,class
      		,is_contact_exchange
            ,is_seller_contact_exchange
        from 
            dma.messenger_chat_scores
        where 
            cast(first_message_event_date as date) between :first_date and :last_date
    )
    select
        cast(first_message_event_date as date) as event_date
        ,'msg' as communication
        ,chat_type as communication_type
        ,chat_subtype as communication_subtype
        ,chr.chat_id as communication_id
        ,first_message_user_id as buyer_id -- сделал первое сообщение и не является владельцем айтема (всегда баер)
        ,user_id as seller_id -- владелец объявления
        ,True as caller_is_buyer
        ,cast(reply_time as date) as reply_date
        ,datediff ('minute', first_message_event_date, reply_time) as reply_time_minutes
        ,chr.item_id as item_id
        ,0 as call_duration
        ,0 as talk_duration
        ,coalesce(not is_spam, False) as is_common_funnel
        ,with_reply and chat_subtype is null and reply_message_bot is null as is_answered
        ,platform_id -- платформа баера
        ,reply_platform_id as seller_platform_id -- платформа селлера
        ,first_message_cookie_id as buyer_cookie_id
        ,cast(NULL as boolean) as is_video_call
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
        ,case 
            when cm.vertical in ('Jobs') and cs.class in (3,4,5) then True
            when cm.vertical not in ('Jobs') and (cs.class in (3,4,5) or is_contact_exchange or is_seller_contact_exchange) then True
            else False
        end as is_target
        ,case
            when cm.vertical in ('Jobs') and cs.class in (3,4,5) then 'target'
            when cm.vertical not in ('Jobs') and (cs.class in (3,4,5) or is_contact_exchange or is_seller_contact_exchange) then 'target'
            when cs.class in (1,2,6,7,8) and with_reply = True then 'preliminary'
            when is_spam = True then 'trash'
            when with_reply = False then 'not_answered'
        end as type
        ,case 
            when class in (3, 4, 5) then to_char(class)
            when is_contact_exchange then '9_contact_exchange_buyer'
            when is_seller_contact_exchange then '10_contact_exchange_seller' 
            else to_char(class) end as tags
        ,case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id
        ,case cl.level when 3 then cl.Location_id end                           as city_id
	    ,cl.LocationGroup_id                                            as location_group_id
	    ,cl.City_Population_Group                                       as population_group
	    ,cl.Logical_Level                                               as location_level_id
    from DMA.messenger_chat_report chr
    left join chat_scores as cs on cs.chat_id = chr.chat_id and cs.item_id = chr.item_id
    left join DMA.current_microcategories cm on cm.microcat_id = chr.microcat_id
    left join DMA.current_locations cl on cl.Location_id = chr.item_location_id
    where True
        -- and not is_spam
        and not is_bad_cookie
        and not is_blocked
        and not is_deleted
        and messages > 0 -- не берем первый этап воронки (создание чата) в этом расчете
        and (
                cast(first_message_event_date as date) between :first_date and :last_date
            or  cast(reply_time as date) between :first_date and :last_date
        )
)
, delivery_orders as (
with  delivery_voided_status as (
                    select
                        deliveryorder_id,
                        platformstatus,
                        min(actual_date) as voided_date
                    from dds.s_deliveryorder_platformstatus
                    where cast(actual_date as date) <= :last_date 
                        and platformstatus in ( 'voided','rejected')
                   --     and deliveryorder_id = 488840500001
                    group by 1, 2
                    having min(actual_date) >= :first_date
                    order by 1
)
select  
        cast(co.pay_date as date) as event_date
        ,'delivery_order' as communication
        ,'' as communication_type
        ,'' as communication_subtype
        ,co.deliveryorder_id as communication_id
        ,buyer_id
        ,coi.seller_id
        ,True as caller_is_buyer
        ,cast (case when ((  (co.workflow = 'delivery-c2c'and platformstatus = 'voided' ) or (co.workflow in ('marketplace-pvz', 'marketplace', 'delivery-b2c', 'delivery-c2c-courier') and platformstatus = 'rejected')) or confirm_date is  null ) then null else  create_date end as date ) as reply_date 
        ,case when (((co.workflow = 'delivery-c2c' and platformstatus = 'voided' ) or (co.workflow in ('marketplace-pvz', 'marketplace', 'delivery-b2c', 'delivery-c2c-courier') and platformstatus = 'rejected')) or confirm_date is  null) then null else datediff ('minute', co.create_date, confirm_date )  end as reply_time_minutes
        ,coi.item_id
        ,0 as call_duration
        ,0 as talk_duration
        ,True is_common_funnel
        ,case when  (((  (co.workflow = 'delivery-c2c' and platformstatus = 'voided' ) or (co.workflow in ('marketplace-pvz', 'marketplace', 'delivery-b2c', 'delivery-c2c-courier') and platformstatus = 'rejected')) or confirm_date is null)) then False else True end as is_answered
        ,co.platform_id as platform_id -- платформа баера
        ,cast(null as int) as seller_platform_id -- платформа селлера
        ,cast(null as int) as buyer_cookie_id
        ,cast(NULL as boolean) as is_video_call
        ,coi.microcat_id
        ,cm.category_id as category_id
        ,coi.location_id
        ,cm.vertical_id
        ,cm.vertical
        ,cm.logical_category_id
        ,cm.logical_category
        ,cm.subcategory_id
        ,cm.Param1_microcat_id as param1_id
        ,cm.Param2_microcat_id as param2_id
        ,cm.Param3_microcat_id as param3_id
        ,cm.Param4_microcat_id as param4_id
        ,case when ((co.workflow = 'delivery-c2c' and platformstatus = 'voided' ) or (co.workflow in ('marketplace-pvz', 'marketplace', 'delivery-b2c', 'delivery-c2c-courier') and platformstatus = 'rejected')  or confirm_date is null) then False else True end is_target
        ,case when ((  (co.workflow = 'delivery-c2c'and  platformstatus = 'voided' ) or (co.workflow in ('marketplace-pvz', 'marketplace', 'delivery-b2c', 'delivery-c2c-courier') and platformstatus = 'rejected')) or confirm_date is null) then  'preliminary' else 'target' end as type
        ,'transactions_order' as tags
        ,case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id
        ,case cl.level when 3 then cl.Location_id end                           as city_id
	    ,cl.LocationGroup_id                                          as location_group_id
	    ,cl.City_Population_Group                                     as population_group
	    ,cl.Logical_Level                                             as location_level_id
from dma.current_order co
join dma.current_order_item coi using (deliveryorder_id)
left join /*+distrib(l,a)*/ dma.current_microcategories as cm 
    on coi.microcat_id = cm.microcat_id
left join /*+distrib(l,a)*/ dma.current_locations as cl 
    on co.warehouse_location_id = cl.location_id
left join delivery_voided_status using (deliveryorder_id)
where true 
        and cast(create_date as date) between :first_date and :last_date 
        and pay_date is not null  
)
,service_orders as (
select 
        cast(sco.create_timestamp as date) as event_date
        ,'service_order' as communication
        ,'' as communication_type
        ,'' as communication_subtype
        ,sco.orderid as communication_id
        ,buyer_id
        ,sco.seller_id
        ,True as caller_is_buyer
        ,cast(sco.accept_timestamp as date) as reply_date
        ,datediff ('minute',create_timestamp, accept_timestamp ) as reply_time_minutes
        ,sco.item_id as item_id
        ,0 as call_duration
        ,0 as talk_duration
        ,True is_common_funnel
        ,case when accepted_flg = 1 then true else false end as is_answered
        ,cast(null as int) as platform_id-- платформа баера ?
        ,cast(null as int) seller_platform_id -- платформа селлера??
        ,cast(null as int) as buyer_cookie_id 
        ,case when accepted_flg = 1 and canceled_flg = 0 then true else false end  as is_target
        ,case when accepted_flg = 1 and canceled_flg = 0 then 'target' else 'preliminary' end as type
        ,'transactions_services_calendar' as tags
from dma.services_calendar_orders sco
where true 
        and cast(create_timestamp as date) between :first_date and :last_date 
)
,  str_orders as (
with confirmed_str_orders as (
with t as(
    select  
        StrBooking_id, 
        CreatedAt as Actual_date, 
        ROW_NUMBER() OVER(PARTITION BY strbooking_id, actual_date::date ORDER BY actual_date desc )  as rn
    from dds.L_STROrderEventname_StrBooking l
        left join dds.S_STROrderEventname_STREventName s1 using (STROrderEventname_id)
        left join dds.S_STROrderEventname_CreatedAt s2 using (STROrderEventname_id)
    where STREventName  = 'confirmed'
  	and  date(actual_date) between :first_date and :last_date 
)
select 
    distinct strbooking_id  
    , Actual_date  as confirmed_time
from t 
where rn = 1 
and  date(actual_date) between :first_date and :last_date
)
,  paid_str_orders  as(
        select
			distinct StrBooking_id as StrBooking_id, CreatedAt as pay_date
        from dds.L_STROrderEventname_StrBooking l
        left join dds.S_STROrderEventname_STREventName s1 using (STROrderEventname_id)
        left join dds.S_STROrderEventname_CreatedAt s2 using (STROrderEventname_id)
		where STREventName = 'paid'
		    and date(CreatedAt) between :first_date and :last_date
)
select 
        cast(stro.order_create_time as date) as event_date
        ,'str_order' as communication
        ,'' as communication_type
        ,'' as communication_subtype
        ,stro.order_id as communication_id
        ,buyer_id
        ,cast(null as int) as seller_id
        ,True as caller_is_buyer
        ,cast(c.confirmed_time as date) as reply_date
        ,datediff ('minute',order_create_time, c.confirmed_time ) as reply_time_minutes
        ,stro.item_id as item_id
        ,0 as call_duration
        ,0 as talk_duration
        ,True is_common_funnel
        ,case when c.confirmed_time is not null then true else false end as is_answered
        ,cast(null as int) as platform_id-- платформа баера ?
        ,cast(null as int) seller_platform_id -- платформа селлера??
        ,cast(null as int) buyer_cookie_id 
        ,case when  pay_date  is not null  then true else false end  as is_target
        ,case when pay_date  is not null  then 'target' else 'preliminary' end as type
        ,'transactions_str' as tags
from dma.short_term_rent_orders stro
left join confirmed_str_orders as c 
    on c.strbooking_id = stro.order_id
left join paid_str_orders as po 
    on po.strbooking_id = stro.order_id
where true 
        and cast(order_create_time as date) between :first_date and :last_date 
)
, se_str_orders as (
select 
    event_date
    ,communication
    ,communication_type
    ,communication_subtype
    ,communication_id
    ,buyer_id
    ,coalesce (seller_id, ci.user_Id) as seller_id
    ,caller_is_buyer
    ,reply_date
    ,reply_time_minutes
    ,t.item_id
    ,call_duration
    ,talk_duration
    ,is_common_funnel
    ,is_answered
    ,platform_id
    ,seller_platform_id
    ,buyer_cookie_id
    ,cast(NULL as boolean) as is_video_call
    ,cm.microcat_id
    ,cm.category_id
    ,cl.location_id
    ,cm.vertical_id
    ,cm.vertical
    ,cm.logical_category_id
    ,cm.logical_category
    ,cm.subcategory_id
    ,cm.Param1_microcat_id as param1_id 
    ,cm.Param2_microcat_id as param2_id
    ,cm.Param3_microcat_id as param3_id
    ,cm.Param4_microcat_id as param4_id
    ,is_target
    ,type
    ,tags
    ,case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id
    ,case cl.level when 3 then cl.Location_id end                           as city_id
	,cl.LocationGroup_id                                          as location_group_id
	,cl.City_Population_Group                                     as population_group
	,cl.Logical_Level                                             as location_level_id
from (
    select * 
        from service_orders
    union all 
    select * 
        from str_orders
    union all 
    select * 
        from gsm_calls
    )t  
join dma.current_item ci using (Item_id)
join dma.current_microcategories cm using (microcat_id)
join dma.current_locations cl using (Location_id)
)
select 
    a.*
    ,coalesce(asd.is_asd, False) as is_asd
    ,asd.user_group_id as asd_user_group_id
    ,coalesce(usm.user_segment, ls.segment) as user_segment_market
from 
    (
        select *
        from iac_calls
        union all 
        select *
        from chats
        union all 
        select *
        from delivery_orders
        union all 
        select * 
        from se_str_orders
    ) as a 
    left join asd on a.seller_id = asd.user_id 
                    and asd.active_from_date interpolate previous value a.event_date
    left join dict.segmentation_ranks ls on ls.logical_category_id = a.logical_category_id 
                    and ls.is_default
    left join usm on a.seller_id = usm.user_id
                    and a.logical_category_id = usm.logical_category_id
                    and usm.converting_date interpolate previous value a.event_date
