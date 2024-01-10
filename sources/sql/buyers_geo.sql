with test_users AS (
            -- Собираем тестовых пользователей
            SELECT User_id AS user_id
            FROM DMA.current_user
            WHERE IsTest
            ORDER BY user_id
)
, item_buy as (
            SELECT distinct csc.cookie_id
                , csc.User_id
                , csc.EventDate::date as event_date
                , lc.logical_category_id
                , lc.vertical_id
            FROM
                DMA.click_stream_contacts csc
                    LEFT JOIN /*+ JTYPE(FM) */ test_users tu
                        ON tu.user_id = csc.item_user_id
                    LEFT JOIN /*+ JTYPE(FM) */ INFOMODEL.current_infmquery_category i
                        ON i.infmquery_id = csc.infmquery_id
                    LEFT JOIN /*+ JTYPE(FM) */ DMA.current_logical_categories lc
                        ON lc.logcat_id = i.logcat_id
                    left join DMA.current_locations cl
                        on cl.Location_id = csc.Location_id
            WHERE TRUE
                and csc.User_id is not null
                AND CAST(csc.EventDate AS DATE) BETWEEN :first_date and :last_date
                AND COALESCE(csc.ishuman_dev, TRUE) -- очистка от ботов
                AND COALESCE(csc.ishuman, TRUE) -- очистка от ботов
                AND csc.last_nondirect_session_source_id IS NOT NULL -- (!) похоже, что в DMA.click_stream_contacts есть такие кортежи (Cookie_id, session_hash), которых нет в DMA.session_source_full (для менее чем 0.1 % ежедневных событий "контакт")
                AND tu.user_id IS NULL -- оставляем только контакты по айтемам, листеры которых не нашлись среди множества тестовых пользователей
                AND i.infm_version IN ('master') -- мастер-версия классификатора
            ORDER BY User_id, event_date
)
select item_buy.cookie_id
    , geo.participant_id as user_id
    , geo.event_date::date as event_date
    , item_buy.logical_category_id
    , item_buy.vertical_id
    -- Dimensions -----------
    , cl.region_internal_id as region_id
    , cl.city_internal_id as city_id
    , cl.LocationGroup_id as location_group_id
    , cl.City_Population_Group as population_group
    , cl.Logical_Level as location_level_id
from DMA.users_home_location_segment geo
inner join DMA.current_locations cl on geo.home_city_id = cl.location_id and cl.region is not null
inner join item_buy on item_buy.User_id = geo.participant_id and item_buy.event_date = geo.event_date
where TRUE
    and geo.participant_type = 'user'
    -- and geo.event_date::date
    and cast(geo.event_date as date) between :first_date and :last_date
ORDER BY geo.participant_id, geo.event_date::date
