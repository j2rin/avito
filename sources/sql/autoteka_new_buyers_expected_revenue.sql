with
das as (
    select
        autotekauser_id,
        reports_count,
        user_created_at,
        event_date,
        searchtype,
        autoteka_platform_id,
        row_number() over (partition by autotekaorder_id order by event_date desc) as rn_order,
        row_number() over (partition by autotekauser_Id order by event_date)       as rn_user
    from dma.autoteka_stream das
    where cast(das.user_created_at as date) >= now() + interval '-395' day
        and cast(das.user_created_at as date) <= now() + interval '-365' day
        and autotekauser_id is not null
        and funnel_stage_id = 4
        and cast(das.event_date as date) between :first_date and :last_date
),
reports_365_grouped as (
    select
        d2.searchtype,
        d2.autoteka_platform_id,
        sum(case when datediff('day', d1.user_created_at, d1.event_date) < 365 then d1.reports_count end) /
        count(distinct d1.autotekauser_id) as avg_reports_365
    from das d1
    join das d2 on d1.autotekauser_id = d2.autotekauser_id and d2.rn_user = 1
    where d1.rn_order = 1
        and d2.autoteka_platform_id is not null
        and d2.searchtype is not null
    group by 1, 2
),
reports_365_total as (
    select
        sum(case when datediff('day', user_created_at, event_date) < 365 then reports_count end) /
        count(distinct autotekauser_id) as avg_reports_365_total
    from das
    where rn_order = 1
),
report_price as (
    select sum(amount) / sum(reports_count) as avg_report_price
    from dma.autoteka_stream
    where funnel_stage_id = 4
        and cast(event_date as date) between :first_date and :last_date
),
new_users as (
    select
        autotekauser_Id,
        autoteka_cookie_id,
        additionalcookie_id,
        cookie_id,
        user_id,
        autoteka_platform_id,
        searchtype,
        event_date,
        row_number() over (partition by autotekauser_id order by event_date) as rn
    from dma.autoteka_stream
    where is_new_user
        and cast(event_date as date) between :first_date and :last_date
),
revenue as (
    select
        das.autotekauser_id,
        amount,
        reports_count,
        das.event_date,
        user_created_at,
        row_number() over (partition by autotekaorder_id order by das.event_date desc) as rn
    from dma.autoteka_stream das
    join new_users nu on nu.autotekauser_id = das.autotekauser_id
    where funnel_stage_id = 4
        and cast(das.event_date as date) between :first_date and :last_date
),
revenue_grouped as (
    select
        autotekauser_id,
        sum(case when datediff('day', user_created_at, event_date) < 365 then amount end)        as amount,
        sum(case when datediff('day', user_created_at, event_date) < 365 then reports_count end) as reports_cnt
    from revenue
    where rn = 1
    group by 1
)
select
    nu.autotekauser_Id,
    nu.autoteka_cookie_id,
    nu.additionalcookie_id,
    nu.cookie_id,
    nu.user_id,
    nu.autoteka_platform_id 												   as platform_id,
    nu.searchtype,
    nu.event_date,
    coalesce(rev.amount, 0)                                                 as amount,
    coalesce(rev.reports_cnt, 0)                                            as reports_cnt,
    coalesce(r.avg_reports_365,
            (select avg_reports_365_total from reports_365_total limit 1)) as reports_next_365_days,
    coalesce(r.avg_reports_365, (select avg_reports_365_total from reports_365_total limit 1)) *
    (select avg_report_price from report_price limit 1)                     as revenue_next_365_days,
    coalesce(r.avg_reports_365, (select avg_reports_365_total from reports_365_total limit 1)) -
    coalesce(rev.reports_cnt, 0)                                            as reports_next_365_days_left,
    coalesce(r.avg_reports_365, (select avg_reports_365_total from reports_365_total limit 1)) *
    (select avg_report_price from report_price limit 1) -
    coalesce(rev.amount, 0)                                                 as revenue_next_365_days_left
from (select * from new_users where rn = 1) nu
left join reports_365_grouped r on r.searchtype = nu.searchtype and r.autoteka_platform_id = nu.autoteka_platform_id
left join revenue_grouped rev on rev.autotekauser_id = nu.autotekauser_id
