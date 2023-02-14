select
    t.event_date,
    t.cookie_id,
    t.user_id,
    t.observation_name,
    observation_value,
    t.platform_id,
    cm.vertical_id,
    cm.logical_category_id,
    cm.category_id,
    cm.subcategory_id,
    cm.Param1_microcat_id   as param1_id,
    cm.Param2_microcat_id   as param2_id,
    cm.Param3_microcat_id   as param3_id,
    cm.Param4_microcat_id   as param4_id,
    cl.region_internal_id   as region_id,
    cl.city_internal_id     as city_id
from (
    (
        select
            bs.event_date,
            bs.cookie_id,
            bs.user_id,
            'delivery_contact' as observation_name,
            1 as observation_value,
            bs.platform_id,
            bs.microcat_id,
            bs.location_id
        from dma.buyer_stream bs
        where bs.item_flags & 4 = 0 and eid in (2015,4035)
            and bs.event_date::date between :first_date and :last_date
    )
    union all
    (
        select
            observation_date,
            case when participant_type = 'visitor' then participant_id end as cookie_id,
            case when participant_type = 'user' 	 then participant_id end as user_id,
            observation_name,
            observation_value,
            platform_id,
            microcat_id,
            location_id
        from dma.matched_anonymous_calls_metric_observation mac
        where observation_name in (
                'answered_proxy_calls', 'call_phone_screen_views_client',
                'missed_proxy_calls','anon_calls_matched_any_type', 'anon_calls_matched_answered',
                'buyer_str_bookings'
            )
            and observation_value>0
            and observation_date::date between :first_date and :last_date
    )
    union all
    (
        select
            first_message_event_date as event_date,
            first_message_cookie_id as cookie_id,
            first_message_user_id as user_id,
            'answered_first_messages' as observation_name,
            1 as observation_value,
            platform_id,
            microcat_id,
            location_id
        from DMA.messenger_chat_report
        where true
            and not is_spam
            and not is_bad_cookie
            and not is_blocked
            and not is_deleted

            and chat_subtype is null
            and with_reply = True
            and reply_message_bot is null
            and datediff ('minute',first_message_event_date, reply_time) between 0 and 4320
            and first_message_event_date::date between :first_date and :last_date
    )
    union all
    (
        select
            AppCallStart::date as event_date,
            case when CallerIsBuyer then CallerDevice 		when not CallerIsBuyer then RecieverDevice 		end as cookie_id,
        	case when CallerIsBuyer then AppCallCaller_id	when not CallerIsBuyer then AppCallReciever_id	end as user_id,
            'appcall_bx_outgoing' as observation_name,
            1 as observation_value,
        	case when CallerIsBuyer then CallerPlatform		when not CallerIsBuyer then RecieverPlatform 	end as platform_id,
            microcat_id,
            location_id
        from dma.app_calls
        where 	CallerIsBuyer
            and AppCallScenario in (
                'call_log_callback',
                'deeplink_call_back',
                'item',
                'item_feed',
                'item_feed_photo',
                'item_gallery',
                'messenger_chat_menu',
                'messenger_empty_chat',
                'notification_call_back'
            )
           and AppCallStart::date between :first_date and :last_date
    )
) t
left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cm on cm.microcat_id = t.microcat_id
left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations cl on cl.Location_id = t.location_id
