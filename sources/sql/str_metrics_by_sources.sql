with
    str_items AS
        (select
            ci.item_id,
            case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
            mic.logical_category_id,
            mic.subcategory_id
        from DMA.current_item ci
            inner join DMA.current_locations cl
                on cl.Location_id = ci.location_id
            inner join DMA.current_microcategories mic
                on ci.microcat_id = mic.microcat_id
                and mic.logical_category = 'Realty.ShortRent'
        ),
    events AS (
        select
            t.event_datetime,
            t.event_date,
            t.cookie_id,
            t.track_id,
            t.event_no,
            t.user_id,
            t.item_id,
            t.x,
            t.x_eid,
            t.eid,
            min(case when t.eid = 300 then t.search_flags end) over (partition by t.cookie_id, t.x order by t.event_datetime rows between unbounded preceding and current row) as serp_search_params,
            min(case when t.eid = 300 then t.query_id end)     over (partition by t.cookie_id, t.x order by t.event_datetime rows between unbounded preceding and current row) as serp_query
        from (
            select
                t.event_date as event_datetime,
                cast(t.event_date as date) as event_date,
                t.cookie_id,
                t.track_id,
                t.event_no,
                t.user_id,
                t.item_id,
                t.x,
                t.x_eid,
                t.eid,
                t.search_flags,
                t.query_id
            from dma.buyer_stream t
            where 1=1
                --- фильтрация на даты
                and cast(t.event_date as date) between :first_date and :last_date
                --and cast(t.date as date) between :first_date and :last_date --@trino
                 -- оставляем только события поиска, просмотра и бронирования
                and t.eid in (300, 301, 2581)
        ) t
    )
select
    iv.event_date,
    iv.cookie_id,
    iv.item_id,
    min(u.user_id) as user_id,
    min(iv.x_eid) as x_eid,
    coalesce(min(iv.sdam_flg), false) as sdam_flg,
    coalesce(min(iv.str_flg), false) as str_flg,
    coalesce(min(iv.date_filtered_flg), false) as date_filtered_flg,
    coalesce(min(iv.text_query_flg), false) as text_query_flg,
    min(iv.region_id) as region_id,
    min(iv.logical_category_id) as logical_category_id,
    min(iv.subcategory_id) as subcategory_id,
    min(iv.item_views_cnt) as item_views_cnt,
    count(o.order_id) as str_created_bookings,
    coalesce(sum(o.gmv), 0) as str_created_gmv,
    coalesce(sum(o.revenue), 0) as str_created_revenue,
    coalesce(sum(o.promo_revenue), 0) as str_created_promo_revenue,
    sum(case when o.paid_flg then 1 else 0 end) as str_paid_bookings,
    sum(case when o.paid_flg then o.gmv else 0 end) as str_paid_gmv,
    sum(case when o.paid_flg then o.revenue else 0 end) as str_paid_revenue,
    sum(case when o.paid_flg then o.promo_revenue else 0 end) as str_paid_promo_revenue
from
        (select
            cookie_id,
            item_id,
            event_date,
            min(region_id) as region_id,
            min(logical_category_id) as logical_category_id,
            min(subcategory_id) as subcategory_id,
            min(x_eid) as x_eid,
            min(sdam_flg) as sdam_flg,
            min(str_flg) as str_flg,
            min(date_filtered_flg) as date_filtered_flg,
            min(text_query_flg) as text_query_flg,
            min(item_views_cnt) as item_views_cnt
        from
            (
            select
                t.cookie_id,
                t.item_id,
                t.event_date,
                str.region_id,
                str.logical_category_id,
                str.subcategory_id,
                first_value(t.x_eid) over (partition by t.cookie_id, t.item_id, t.event_date order by t.event_datetime) as x_eid,
                --- следующие поля актуальны только если предыдущее поле x_eid = 300
                first_value(bitwise_and(serp_search_params, 4503599627370496) > 0) over (partition by t.cookie_id, t.item_id, t.event_date order by t.event_datetime) as sdam_flg,
                first_value(bitwise_and(serp_search_params, 2251799813685248) > 0) over (partition by t.cookie_id, t.item_id, t.event_date order by t.event_datetime) as str_flg,
                first_value(bitwise_and(serp_search_params, 1125899906842624) > 0) over (partition by t.cookie_id, t.item_id, t.event_date order by t.event_datetime) as date_filtered_flg,
                first_value(coalesce(serp_query is not null, false)) over (partition by t.cookie_id, t.item_id, t.event_date order by t.event_datetime) as text_query_flg,
                ---
                sum(1) over (partition by t.cookie_id, t.item_id, t.event_date) as item_views_cnt
            from events as t
            inner join str_items as str
                on t.item_id = str.item_id
                and t.eid = 301
            ) t
        group by 1, 2, 3
        ) as iv
    left join (
            select
                cookie_id,
                event_date,
                min(user_id) as user_id
            from (
                select
                    cookie_id,
                    event_date,
                    first_value(t.user_id) over (partition by t.cookie_id, t.event_date order by t.min_event_datetime) as user_id
                from (
                    select
                        user_id,
                        event_date,
                        min(cookie_id) as cookie_id,
                        min(min_event_datetime) as min_event_datetime
                    from
                        (
                        select
                            t.user_id,
                            t.event_date,
                            first_value(t.cookie_id) over (partition by t.user_id, t.event_date order by t.event_datetime) as cookie_id,
                            min(t.event_datetime) over (partition by t.user_id, t.event_date) as min_event_datetime
                        from events as t
                        where 1=1
                            and user_id is not null
                            and cookie_id is not null
                        ) t
                    group by 1, 2
                ) t
            ) t
            group by 1, 2
            ) as u
        on iv.cookie_id = u.cookie_id
        and iv.event_date = u.event_date
    left join (
            select
                event_date,
                user_id,
                item_id,
                min(cookie_id) as cookie_id
            from (
                select
                    event_date,
                    user_id,
                    item_id,
                    first_value(cookie_id) over (partition by event_date, user_id, item_id order by event_datetime) as cookie_id
                from
                    events
                where
                    eid = 2581
                ) t
            group by 1, 2, 3
            ) as bfc
        on iv.cookie_id = bfc.cookie_id
        and iv.item_id = bfc.item_id
        and iv.event_date = bfc.event_date
    left join (
            select
                s.order_id,
                order_create_time,
                cast(order_create_time as date) as event_date,
                buyer_id,
                s.item_id,
                p.order_id is not null as paid_flg,
                coalesce(amount, 0) as gmv,
                cast(coalesce(payout_fee, 0) / 100 as decimal) + coalesce(trx_promo_fee, 0) as revenue,
                coalesce(trx_promo_fee, 0) as promo_revenue
            from
                dma.short_term_rent_orders s
                left join (
                        SELECT
                            DISTINCT StrBooking_id as order_id
                        FROM (
                            SELECT
                                DISTINCT STROrderEventname_id
                            FROM dds.S_STROrderEventname_CreatedAt
                                WHERE CreatedAt::date between :first_date and :last_date
                        ) AS s1
                        JOIN (
                            SELECT
                                DISTINCT STROrderEventname_id
                            FROM dds.S_STROrderEventname_STREventName
                                WHERE STREventName = 'paid'
                        ) AS s2
                        ON s1.STROrderEventname_id = s2.STROrderEventname_id
                        JOIN (
                            SELECT
                                DISTINCT
                                STROrderEventname_id,
                                StrBooking_id
                            FROM dds.L_STROrderEventname_StrBooking
                        ) AS l
                        ON l.STROrderEventname_id = s2.STROrderEventname_id
                        ) as p
                    on s.order_id = p.order_id
            where cast(s.order_create_time as date) between :first_date and :last_date
            ) as o
        on bfc.user_id = o.buyer_id
        and iv.event_date = o.event_date
        and iv.item_id = o.item_id
group by 1, 2, 3