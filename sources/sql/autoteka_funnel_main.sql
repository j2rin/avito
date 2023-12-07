with
events as (
    select track_id,
           event_no,
           event_date,
           autoteka_cookie_id,
           event_type,
           autoteka_platform_id,
           null as is_pro,
           null as searchtype
    from dma.autoteka_report_stream
    where cast(event_date as date) between :first_date and :last_date
        and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date)
    union all
    select track_id,
           event_no,
           event_date,
           autoteka_cookie_id,
           case
               when funnel_stage_id = 0 then 'main'
               when funnel_stage_id = 1 then 'preview'
               when funnel_stage_id = 2 then 'selection'
               when funnel_stage_id = 3 then 'paypage'
               when funnel_stage_id = 4 then 'callback'
               end as event_type,
           autoteka_platform_id,
           is_pro,
           searchtype
    from dma.autoteka_stream
    where cast(event_date as date) between :first_date and :last_date
        and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date)
),
events_interpolated as (
    select
        track_id
        , event_no
        , event_date
        , autoteka_cookie_id
        , event_type
        , searchtype
        , case
            when autoteka_platform_id is not null then autoteka_platform_id
            else
                coalesce(last_value(autoteka_platform_id)
                         over (partition by autoteka_cookie_id
                             , cast(event_date as date) order by event_date rows between unbounded preceding and current row )
                    , last_value(autoteka_platform_id)
                      over (partition by autoteka_cookie_id
                          , cast(event_date as date) order by event_date desc rows between unbounded preceding and current row )) end as platform_id
        , case
            when is_pro is not null then is_pro
            else
                coalesce(last_value(is_pro)
                         over (partition by autoteka_cookie_id
                             , cast(event_date as date) order by event_date rows between unbounded preceding and current row )
                    , last_value(is_pro)
                      over (partition by autoteka_cookie_id
                          , cast(event_date as date) order by event_date desc rows between unbounded preceding and current row )) end as ispro
    from events
),
events_lag as (
    select
        track_id
      , event_no
      , event_date
      , autoteka_cookie_id
      , event_type
      , searchtype
      , platform_id
      , ispro
      , date_diff('second'
      , lag(event_date) over (partition by autoteka_cookie_id order by event_date)
      , event_date)     as second_diff
      , case
            when date_diff('second'
                     , lag(event_date) over (partition by autoteka_cookie_id order by event_date)
                     , event_date)
                <= 1800 then 0
            else 1 end as new_session
    from events_interpolated
    where autoteka_cookie_id is not null
),
autoteka_sessions as (
    select
        track_id,
        event_no,
        event_date,
        autoteka_cookie_id,
        event_type,
        platform_id,
        searchtype,
        ispro,
        cast(autoteka_cookie_id as varchar) || '|' || cast(sum(new_session)
                                     over (partition by autoteka_cookie_id order by event_date rows between unbounded preceding and current row) as varchar) as cookie_session
    from events_lag
),
autoteka_sessions_searchtype as (
    select
    track_id,
        event_no,
        event_date,
        autoteka_cookie_id,
        event_type,
        platform_id,
        searchtype,
        ispro,
        cookie_session,
        case
            when searchtype is not null then searchtype
            else coalesce(first_value(searchtype
                                        -- ) --@trino
                                            IGNORE NULLS
                                        -- ) --@vertica
                          over (partition by cookie_session order by event_no rows between current row and unbounded following),
                          last_value(searchtype
                                        -- ) --@trino
                                            IGNORE NULLS
                                        -- ) --@vertica
                          over (partition by cookie_session order by event_no rows between unbounded preceding and current row)
                ) end as search_type
    from autoteka_sessions
)
select track_id,
       event_no,
       event_date,
       autoteka_cookie_id,
       event_type,
       platform_id,
       search_type             as searchtype,
       from_big_endian_64(xxhash64(cast(coalesce(cs.cookie_session, '') as varbinary))) as cookie_session,
       to_exclude_pay_callback as is_session_to_exclude,
       main_page_session       as is_main_page_session,
       is_pro_user             as is_pro
from autoteka_sessions_searchtype cs
join (
    select
        cookie_session,
        case
          when min(case
                       when event_type in ('view', 'link_share', 'download')
                           then event_date end) is not null and
               min(case when event_type in ('callback', 'paypage') then event_date end) is null
              then True
          else False end                                         as to_exclude_pay_callback,
        max(case when event_type = 'main' then True else True end) as main_page_session,
        max(case when ispro then True else False end)              as is_pro_user
    from autoteka_sessions_searchtype
    group by 1
) cs_agg on cs_agg.cookie_session = cs.cookie_session
