-- Breakdowns Materialization ==============================================================================================================
-- Конфигурируем фильтры для брейкдаунов
drop table if exists public.ab_traffic_estimation_breakdowns_map;
create table public.ab_traffic_estimation_breakdowns_map as (
    --explain
    with
    capitals as (
        select  region
        from    dma.m42_region
        where   region in ('Москва', 'Москва и Московская область', 'Московская область', 'Ленинградская область', 'Санкт-Петербург', 'Санкт-Петербург и Ленинградская область')
    ),
    regions as (
        select  region from dma.m42_regio where region not in ('Any', 'Undefined', 'Москва', 'Москва и Московская область', 'Московская область', 'Ленинградская область', 'Санкт-Петербург', 'Санкт-Петербург и Ленинградская область')
    ),
    breakdowns_map as (
        select  rn as breakdown_id, c.category_id, c.category, s.subcategory_id, s.subcategory, l.logical_category_id, l.logical_category, r.region_id, r.region, us.item_user_segment
        from        dma.m42_category c
        cross join  dma.m42_subcategory s
        cross join  dma.m42_region r
        cross join  dma.m42_logical_category l
        cross join  (select 'ASD' as item_user_segment union select 'Pro' union select 'Private' union select 'Any') us
        cross join  (select num as rn from dict.natural_number where num <= 15) rn
        where   false
            -- Недвижимость Тотал
            or  (rn = 1 and c.category = 'Недвижимость' and s.subcategory = 'Any' and l.logical_category = 'Any' and r.region = 'Any' and us.item_user_segment = 'Any')
            -- Недвижимость Столицы
            or  (rn = 2 and c.category = 'Недвижимость' and s.subcategory = 'Any' and l.logical_category = 'Any' and r.region in (select * from capitals) and us.item_user_segment = 'Any')
            -- Недвижимость Дорогие категории
            or  (rn = 3 and c.category = 'Недвижимость' and s.subcategory in ('Квартиры', 'Коммерческая недвижимость', 'Дома, дачи, коттеджи') and l.logical_category = 'Any' and r.region = 'Any' and us.item_user_segment = 'Any')
            -- Недвижимость Квартиры Столицы
            or  (rn = 4 and c.category = 'Недвижимость' and s.subcategory in ('Квартиры') and l.logical_category = 'Any' and r.region in (select * from capitals) and us.item_user_segment = 'Any')
            -- Недвижимость Коммерческая Столицы
            or  (rn = 5 and c.category = 'Недвижимость' and s.subcategory in ('Коммерческая недвижимость') and l.logical_category = 'Any' and r.region in (select * from capitals) and us.item_user_segment = 'Any')
            -- Недвижимость Квартиры Регионы
            or  (rn = 6 and c.category = 'Недвижимость' and s.subcategory in ('Квартиры') and l.logical_category = 'Any' and r.region in (select * from regions) and us.item_user_segment = 'Any')
            -- Недвижимость Коммерческая Регионы
            or  (rn = 7 and c.category = 'Недвижимость' and s.subcategory in ('Коммерческая недвижимость') and l.logical_category = 'Any' and r.region in (select * from regions) and us.item_user_segment = 'Any')
            -- Недвижимость Прочее Столицы
            or  (rn = 8 and c.category = 'Недвижимость' and s.subcategory in ('Комнаты', 'Недвижимость за рубежом', 'Гаражи и машиноместа', 'Земельные участки', 'Дома, дачи, коттеджи') and l.logical_category = 'Any' and r.region in (select * from capitals) and us.item_user_segment = 'Any')
            -- Недвижимость Прочее Регионы
            or  (rn = 9 and c.category = 'Недвижимость' and s.subcategory in ('Комнаты', 'Недвижимость за рубежом', 'Гаражи и машиноместа', 'Земельные участки', 'Дома, дачи, коттеджи') and l.logical_category = 'Any' and r.region in (select * from regions) and us.item_user_segment = 'Any')

            -- Траспорт Тотал
            or  (rn = 10 and c.category = 'Транспорт' and s.subcategory = 'Any' and l.logical_category = 'Any' and r.region = 'Any' and us.item_user_segment = 'Any')
            -- Траспорт Столицы
            or  (rn = 11 and c.category = 'Транспорт' and s.subcategory = 'Any' and l.logical_category = 'Any' and r.region in (select * from capitals) and us.item_user_segment = 'Any')
            -- Траспорт Pro + ASD
            or  (rn = 12 and c.category = 'Транспорт' and s.subcategory = 'Any' and l.logical_category = 'Any' and r.region = 'Any' and us.item_user_segment in ('ASD', 'Pro'))
            -- Траспорт Pro
            or  (rn = 13 and c.category = 'Транспорт' and s.subcategory = 'Any' and l.logical_category = 'Any' and r.region = 'Any' and us.item_user_segment = 'ASD')
            -- Траспорт Автомобили
            or  (rn = 14 and c.category = 'Транспорт' and s.subcategory in ('Автомобили') and l.logical_category = 'Any' and r.region = 'Any' and us.item_user_segment = 'Any')
            -- Траспорт Запчасти
            or  (rn = 15 and c.category = 'Транспорт' and s.subcategory in ('Запчасти и аксессуары') and l.logical_category = 'Any' and r.region = 'Any' and us.item_user_segment = 'Any')
    )
    select * from breakdowns_map
) order by category_id, subcategory_id, logical_category_id, region_id, item_user_segment unsegmented all nodes;

select analyze_statistics('public.ab_traffic_estimation_breakdowns_map');

-- Красивый справочник брейкдаунов
drop table if exists public.ab_traffic_estimation_breakdowns;
create table public.ab_traffic_estimation_breakdowns as (
    with
    breakdowns as (
        select  breakdown_id,
                max(case when pf = 'c' then v end) as category,
                max(case when pf = 'sc' then v end) as subcategory,
                max(case when pf = 'lc' then v end) as logical_category,
                max(case when pf = 'r' then v end) as region,
                max(case when pf = 'seg' then v end) as item_user_segment,
                listagg(case when v = 'Any' then '' else pf || '[' || v || ']' end USING PARAMETERS separator = '', max_length=10000) as breakdown
        from (
            select  breakdown_id,
                    pf,
                    listagg(v USING PARAMETERS separator = '|', max_length=10000) as v
            from (
                select  breakdown_id,
                        decode(rn, 1, 'c', 2, 'sc', 3, 'lc', 4, 'r', 5, 'seg') as pf,
                        decode(rn, 1, category, 2, subcategory, 3, logical_category, 4, region, 5, item_user_segment) as v
                from    public.ab_traffic_estimation_breakdowns_map
                cross join  (select num as rn from dict.natural_number where num <= 5) rn
                group by 1, 2, 3
            ) b
            group by 1, 2
        ) b
        group by 1
    )
    select  *
    from    breakdowns
) order by breakdown_id unsegmented all nodes;

select analyze_statistics('public.ab_traffic_est_breakdowns');


-- Main table ===============================================================================================================================
drop table if exists public.ab_traffic_estimation_metrics_stats;
create table public.ab_traffic_estimation_metrics_stats as /*+direct*/
with
calendar as (
    select  event_date,
            conditional_change_event(date_trunc('week', event_date)) over (order by event_date desc) + 1 as week
    from    dma.calendar
    where   event_date between '2019-07-01'::date and '2019-07-21'::date
),
observations as (
    select  participant_id,
            platform_id,
            item_id,
            session_no,
            observation_date,
            c.week,
            category_id,
            subcategory_id,
            logical_category_id,
            case when l.level = 2 then l.location_id when l.level = 3 then l.ParentLocation_id end as region_id,
            item_user_segment,
            sum(observation_value) as contacts
    from    dma.search_stream_metric_observation mo
    inner join calendar                          c  on  c.event_date = mo.observation_date
    left join dma.current_locations l on l.location_id = mo.location_id
    where   participant_type = 'visitor'
        and observation_name in ('phone_views_total', 'booking_created_short_rent', 'first_messages', 'delivery_order_created', 'realty_development_phone_views')
        and platform_id <= 4
    group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
),
metrics as (
    select  'contacts' as metric
    union select 'buyers'
    union select 'contacts_grouped'
    union select 'sessions_contact'
),
weeks as (
    select num as weeks from dict.natural_number where num <= 3
),
participant_numerator as (
    select  bucket,
            platform_id,
            w.weeks,
            metric,
            breakdown_id,
            sum(numerator) as numerator
    from (
        select  bucket,
                platform_id,
                week,
                metric,
                breakdown_id,
                case when metric = 'contacts' then sum(contacts) else count(distinct groupkey) end as numerator
        from (
            select  -- Бакеты для облегчения запроса
                    hash(d.participant_id) % 2000 as bucket,
                    d.platform_id,
                    d.week,
                    m.metric,
                    b.breakdown_id,
                        case
                        when m.metric = 'contacts' then 0
                        when m.metric = 'contacts_grouped' then hash(participant_id, observation_date, item_id)
                        when m.metric = 'buyers' then hash(participant_id, observation_date)
                        when m.metric = 'sessions_contact' then hash(participant_id, observation_date, session_no)
                        end as
                    groupkey,
                    sum(d.contacts) as contacts
            from    observations d
            cross join metrics m
            inner join public.ab_traffic_estimation_breakdowns_map b
                on  d.category_id <=> decode(b.category_id, -1, d.category_id, b.category_id)
                and d.subcategory_id <=> decode(b.subcategory_id, -1, d.subcategory_id, b.subcategory_id)
                and d.logical_category_id <=> decode(b.logical_category_id, -1, d.logical_category_id, b.logical_category_id)
                and d.region_id <=> decode(b.region_id, -1, d.region_id, b.region_id)
                and d.item_user_segment <=> decode(b.item_user_segment, 'Any', d.item_user_segment, b.item_user_segment)
            group by 1, 2, 3, 4, 5, 6
        ) d
        group by 1, 2, 3, 4, 5
    ) d
    inner join  weeks w on d.week <= w.weeks
    group by 1, 2, 3, 4, 5
),
participant_denominator as (
    select  hash(mo.participant_id) % 2000 as bucket,
            mo.platform_id,
            w.weeks,
            count(distinct mo.participant_id) as denominator,
            count(distinct mo.participant_id) as participants_count
    from    dma.search_stream_metric_observation mo
    inner join calendar                          c  on  c.event_date = mo.observation_date
    inner join  weeks w on c.week <= w.weeks
    where   participant_type = 'visitor'
        and mo.platform_id <= 4
    group by 1, 2, 3
),
metric_values as (
    select  platform_id,
            weeks,
            breakdown_id,
            metric,
            -- Линеаризация Ratio
            (numerator - num_sum / den_sum * denominator) / den_mean + num_sum / den_sum as value,
            participants_count,
            numerator,
            denominator
    from (
        select  n.*,
                d.denominator,
                d.participants_count,
                sum(n.numerator) over(partition by n.weeks, n.platform_id, n.breakdown_id, n.metric) as num_sum,
                sum(d.denominator) over(partition by n.weeks, n.platform_id, n.breakdown_id, n.metric) as den_sum,
                avg(d.denominator) over(partition by n.weeks, n.platform_id, n.breakdown_id, n.metric) as den_mean
        from    participant_denominator d
        join    participant_numerator   n   on  d.bucket = n.bucket
                                            and d.weeks = n.weeks
                                            and d.platform_id = n.platform_id
    ) m
),
metrics_stats as (
    select  platform_id,
            weeks,
            breakdown_id,
            metric,
            avg(value) as mean,
            -- Приведение бакетного std к std по исходной выборке: std[N] = sqrt(var[B] / size[B] * size[N])
            sqrt(var_samp(value) / count(*) * sum(participants_count)) as std,
            sum(participants_count) as participants_count_100
    from    metric_values t
    group by 1, 2, 3, 4
)
select * from metrics_stats
order by platform_id, weeks, breakdown_id, metric segmented by hash(platform_id, weeks, breakdown_id, metric) all nodes
;

-- Tableau view ============================================================================================================================
create or replace view public.tv_ab_traffic_estimation as
with
shares as (select 0.05 * num as traffic_share from dict.natural_number where num <= 10),
alphas as (
            select  0.05 as alpha, 1.9718962236316093 as t
    union   select  0.01 as alpha, 2.6006344361650386 as t
    union   select  0.005 as alpha, 2.838513688203153 as t
),
betas as (
            select  0.2 as beta, 0.8434221315352971 as t
    union   select  0.1 as beta, 1.2857987939945952 as t
)
select  p.platform,
        s.weeks,
        b.*,
        s.metric,
        s.mean,
        s.std,
        s.participants_count_100,
        traffic_share,
        alpha,
        beta,
        -- Относительный MDE
        (alphas.t + betas.t) * s.std * sqrt(2 / (s.participants_count_100 * traffic_share)) / s.mean as mde
from    public.ab_traffic_estimation_metrics_stats  s
join    public.ab_traffic_estimation_breakdowns     b on b.breakdown_id = s.breakdown_id
join    dma.m42_platform p on p.platform_id = s.platform_id
cross join shares
cross join alphas
cross join betas
;


-- Test ====================================================================================================================================
-- Тестируем, что все корректно считается на примере метрики sessions_contact
with data as (
    select  participant_id,
            count(distinct case when contacts > 0 then hash(observation_date, session_no) else null end) as sessions_contact
    from (
        select  participant_id,
                item_id,
                observation_date,
                session_no,
                sum(case when observation_name in ('phone_views_total', 'booking_created_short_rent', 'first_messages', 'delivery_order_created', 'realty_development_phone_views')
                    and category_id in (39) then observation_value else 0 end) as contacts
        from    dma.search_stream_metric_observation mo
        left join dma.current_locations l on l.location_id = mo.location_id
        where   observation_date::date between '2019-07-01'::date and '2019-07-21'
            and participant_type = 'visitor'
            and platform_id = 1
        group by 1, 2, 3, 4
    ) d
    group by 1
)
select  avg(sessions_contact) as mean, stddev_samp(sessions_contact) as std, count(*) as participants_count
from data
;

select * from public.ab_traffic_estimation_metrics_stats where platform_id = 1 and metric = 'sessions_contact' and breakdown_id = 1 and weeks = 3;
