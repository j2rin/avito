with
    events as (
    select *, 
        case when final_event in (
                                                    81587250006, --	2270	HelpCenter / Просмотр страницы статьи
                                                    81587250008, --	2274	HelpCenter / Лайк статьи
                                                    165533750014, --	2938	HelpCenter / Окончание просмотра/закрытие страницы статьи
                                                    185577250001 --    3416    HelpCenter / CES Article
                ) then 1 end as is_end_article_event
    from (
    select
        cast(event_date as date) as observation_date,
        platform_id,
        user_id,
        Cookie_id as cookie_id,
        session_hash,
        eventtype_id,
        problem_id,
        ces_article_id,
        last_value(EventType_id) over(partition by session_hash order by event_date desc ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as final_event,
        CASE WHEN eventtype_id IN (81587250006)  --	2270	HelpCenter / Просмотр страницы статьи
        		THEN 1 END is_article_views,
        CASE WHEN eventtype_id IN (81587250006)  --	2270	HelpCenter / Просмотр страницы статьи
        	  and problem_id is null
        		THEN 1 END is_nw_article_views,
        CASE WHEN ces_article_id = 3750001 and eventtype_id = 185577250001 
                THEN 1 END is_helpcenter_article_like,
        CASE WHEN ces_article_id = 49500001 and eventtype_id = 185577250001 
                then 1 end is_helpcenter_article_dislike,
        CASE WHEN eventtype_id IN (98556500001)  --	2346	HelpCenter / Запрос на отображения телефона
        		THEN 1 END is_helpcenter_phone_requests,
        CASE WHEN eventtype_id IN (98556500001) --	2346	HelpCenter / Запрос на отображения телефона
        	  and problem_id in (39956000017, 39956000194)
        		THEN 1 END is_helpcenter_phone_moder_block_requests,
        CASE WHEN eventtype_id IN (98556500001) --	2346	HelpCenter / Запрос на отображения телефона
              and problem_id in (39956000018, 39956000195, 40583250009)
        		THEN 1 END is_helpcenter_phone_moder_reject_requests,
        case when EventType_id not in (328682250001,  -- 4771 Support / MSG Chat / Create
                                        54245750002   -- 802 Helpdesk / Тикет / Создание тикета
                 ) then 1 end as is_hc_event,
        case when Eventtype_id IN (137236000001, --	2663	HelpCenter / Ввод номера объявления
        						    134010250001, --	2635	HelpCenter / Выбор темы обращения
        					     	179237000001 --	3249	HelpCenter / Открытие визарда создания обращения
        	     ) then 1 end as is_wizard_event,
        case when eventtype_id = 81587250006 --	2270	HelpCenter / Просмотр страницы статьи
        	      then 1 end as is_article_event,
        case when problem_id is not null and eventtype_id = 81587250006 --	2270	HelpCenter / Просмотр страницы статьи
        	      then 1 end as is_wiz_article_event,
        case when EventType_id in (328682250001, -- 4771 Support / MSG Chat / Create
                                                    54245750002, -- 802 Helpdesk / Тикет / Создание тикета
                                                    98556500001  --	2346	HelpCenter / Запрос на отображения телефона
                  )then 1 end as is_invoice_event
        from DMA.click_stream_helpcenter_user ss
            where 1=1
            and ss.EventType_id IN (
            						-- HC EVENTS
            						81587250001,  --	2276	HelpCenter / Отправлен поисковый запрос
            						81587250002,  --	2273	HelpCenter / Просмотр страницы секции
            						81587250003,  --	2271	HelpCenter / Просмотр главной страницы
            						81587250005,  --	2275	HelpCenter / Дизлайк статьи
            						81587250006,  --	2270	HelpCenter / Просмотр страницы статьи
            						81587250008,  --	2274	HelpCenter / Лайк статьи
            						81587250009,  --	2272	HelpCenter / Просмотр страницы категории
            						98556500001,  --	2346	HelpCenter / Запрос на отображения телефона
            						102112500001, --	2358	HelpCenter / Фокус на поле поиска
            						102541250002, --	2359	HelpCenter / Отображение саджеста
            						116182250004, --	2471	HelpCenter / Показать все темы
            						124771750001, --	2551	HelpCenter / Показ плашки с контактами Support
              						165533750014, --	2938	HelpCenter / Окончание просмотра/закрытие страницы статьи
              						185577250001, --    3416    HelpCenter / CES Article
            						-- WIZARD EVENTS
            						137236000001, --	2663	HelpCenter / Ввод номера объявления
            						134010250001, --	2635	HelpCenter / Выбор темы обращения
            						179237000001,  --	3249	HelpCenter / Открытие визарда создания обращения
            						328682250001, -- 4771 Support / MSG Chat / Create
            						54245750002 -- 802 Helpdesk / Тикет / Создание тикета
            					)
    		and cast(event_date as date) >= date('2022-01-01'))r)
    , sessions as (
        select
            ss.session_hash
            , ss.platform_id
            , cookie_id as participant_id
            , 'cookie' as participant_type
            , min(observation_date) as observation_date
            , sum(is_article_views) as article_views
            , sum(is_nw_article_views) as nw_article_views
            , sum(is_helpcenter_article_like) as helpcenter_article_like
            , sum(is_helpcenter_article_dislike) as helpcenter_article_dislike
            , sum(is_helpcenter_phone_requests) as helpcenter_phone_requests
            , sum(is_helpcenter_phone_moder_block_requests) as helpcenter_phone_moder_block_requests
            , sum(is_helpcenter_phone_moder_reject_requests) as helpcenter_phone_moder_reject_requests
            , max(is_hc_event) as is_hc_session
            -- , max(is_target_event) as is_target_session
            , max(is_wizard_event) as is_wizard_session
        	, max(is_article_event) as is_article_session
        	, max(is_wiz_article_event) as is_wiz_article_session
            , max(is_invoice_event) as is_invoice_session
            , max(is_end_article_event) as is_end_article_session
            , count(eventtype_id) as no_events
            , coalesce(max(ss.EventType_id not in (328682250001, -- 4771 Support / MSG Chat / Create
                                                    54245750002 -- 802 Helpdesk / Тикет / Создание тикета
                                                                                                            )), false) and (count(ss.EventType_id) >= 2 or coalesce(max(ss.EventType_id = 81587250006 --	2270	HelpCenter / Просмотр страницы статьи
                                                                                                            ), false)) as is_target_session
            from events ss
            group by 1,2,3
            UNION
            select
            ss.session_hash
            , ss.platform_id
            , user_id as participant_id
            , 'user' as participant_type
            , min(observation_date) as observation_date
            , sum(is_article_views) as article_views
            , sum(is_nw_article_views) as nw_article_views
            , sum(is_helpcenter_article_like) as helpcenter_article_like
            , sum(is_helpcenter_article_dislike) as helpcenter_article_dislike
            , sum(is_helpcenter_phone_requests) as helpcenter_phone_requests
            , sum(is_helpcenter_phone_moder_block_requests) as helpcenter_phone_moder_block_requests
            , sum(is_helpcenter_phone_moder_reject_requests) as helpcenter_phone_moder_reject_requests
            , max(is_hc_event) as is_hc_session
            -- , max(is_target_event) as is_target_session
            , max(is_wizard_event) as is_wizard_session
        	, max(is_article_event) as is_article_session
        	, max(is_wiz_article_event) as is_wiz_article_session
            , max(is_invoice_event) as is_invoice_session
            , max(is_end_article_event) as is_end_article_session
            , count(eventtype_id) as no_events
            , coalesce(max(ss.EventType_id not in (328682250001, -- 4771 Support / MSG Chat / Create
                                                    54245750002 -- 802 Helpdesk / Тикет / Создание тикета
                                                                                                            )), false) and (count(ss.EventType_id) >= 2 or coalesce(max(ss.EventType_id = 81587250006 --	2270	HelpCenter / Просмотр страницы статьи
                                                                                                            ), false)) as is_target_session
            from events ss
            group by 1,2,3
                ),
            tab as(
            select *,
                    case when (is_wiz_article_session is null and is_article_session = 1 and is_invoice_session is null) then 1 end as only_nw_article_sessions,
                    case when (is_wiz_article_session is null  and is_article_session = 1 and is_invoice_session = 1) then 1 end as invoice_nw_article_sessions,
                    case when (is_article_session is null and is_invoice_session = 1) then 1  end as only_invoice_sessions,
                    case when (is_end_article_session = 1 and is_invoice_session is null) then 1 end as end_on_article_sessions
            from sessions
            )
        , base as (
        select
        	hc.observation_date,
            hc.platform_id,
            hc.participant_id,
            'cookie' as participant_type,
            sum(article_views) as article_views,
            sum(nw_article_views) as nw_article_views,
            sum(helpcenter_article_like) as helpcenter_article_like,
            sum(helpcenter_article_dislike) as helpcenter_article_dislike,
            sum(helpcenter_phone_requests) as helpcenter_phone_requests,
            sum(helpcenter_phone_moder_block_requests) as helpcenter_phone_moder_block_requests,
            sum(helpcenter_phone_moder_reject_requests) as helpcenter_phone_moder_reject_requests,
            sum(hc.is_hc_session) as helpcenter_sessions,
            sum(hc.is_article_session) as article_sessions,
            sum(case when hc.is_target_session then 1 end) as target_sessions,
            sum(hc.is_wizard_session) as wizard_sessions,
            count(case when hc.is_wiz_article_session is null and hc.is_article_session = 1 and hc.is_invoice_session is null then hc.session_hash else null end) as only_nw_article_sessions,
            count(case when hc.is_wiz_article_session is null  and hc.is_article_session = 1 and hc.is_invoice_session = 1 then hc.session_hash else null end) as invoice_nw_article_sessions,
            count(case when hc.is_article_session is null and hc.is_invoice_session = 1 then hc.session_hash else null end) as only_invoice_sessions,
            count(case when hc.is_end_article_session = 1 and hc.is_invoice_session is null then hc.session_hash else null end) as end_on_article_sessions
        from sessions hc 
        WHERE 1=1
        AND hc.participant_id is not null
        and participant_type = 'cookie'
        GROUP BY 1, 2, 3
        UNION
         select
        	hc.observation_date,
            hc.platform_id,
            hc.participant_id,
            'user' as participant_type,
            sum(article_views) as article_views,
            sum(nw_article_views) as nw_article_views,
            sum(helpcenter_article_like) as helpcenter_article_like,
            sum(helpcenter_article_dislike) as helpcenter_article_dislike,
            sum(helpcenter_phone_requests) as helpcenter_phone_requests,
            sum(helpcenter_phone_moder_block_requests) as helpcenter_phone_moder_block_requests,
            sum(helpcenter_phone_moder_reject_requests) as helpcenter_phone_moder_reject_requests,
            sum(hc.is_hc_session) as helpcenter_sessions,
            sum(hc.is_article_session) as article_sessions,
            sum(case when hc.is_target_session then 1 end) as target_sessions,
            sum(hc.is_wizard_session) as wizard_sessions,
            count(case when hc.is_wiz_article_session is null and hc.is_article_session = 1 and hc.is_invoice_session is null then hc.session_hash else null end) as only_nw_article_sessions,
            count(case when hc.is_wiz_article_session is null  and hc.is_article_session = 1 and hc.is_invoice_session = 1 then hc.session_hash else null end) as invoice_nw_article_sessions,
            count(case when hc.is_article_session is null and hc.is_invoice_session = 1 then hc.session_hash else null end) as only_invoice_sessions,
            count(case when hc.is_end_article_session = 1 and hc.is_invoice_session is null then hc.session_hash else null end) as end_on_article_sessions
        from sessions hc 
        WHERE 1=1
        AND hc.participant_id is not null
        and participant_type = 'user'
        GROUP BY 1, 2, 3)
select
    b.observation_date as event_date
    , b.platform_id
    , case when b.participant_type = 'cookie' then b.participant_id end as cookie_id
  	, case when b.participant_type = 'user'    then b.participant_id end as user_id
    , b.participant_id
    , b.helpcenter_sessions
    , b.article_sessions
    , b.target_sessions
    , b.wizard_sessions
    , b.only_nw_article_sessions
    , b.invoice_nw_article_sessions
    , b.only_invoice_sessions
    , b.end_on_article_sessions
    , b.article_views
    , b.nw_article_views
    , case when b.target_sessions = 0 then 0 else b.nw_article_views/b.target_sessions end as nw_article_views_by_session
    , b.helpcenter_article_like
    , b.helpcenter_article_dislike
    , b.helpcenter_phone_requests
    , b.helpcenter_phone_moder_block_requests
    , b.helpcenter_phone_moder_reject_requests
from base b
where cast(observation_date as date) between :first_date and :last_date
