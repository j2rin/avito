with /*+ENABLE_WITH_CLAUSE_MATERIALIZATION */
    str_items AS
        (select
            ci.item_id,
            case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
            mic.logical_category_id,
            mic.subcategory_id
        from DMA.current_item ci
            inner join DMA.current_locations cl
                on 1=1
                and cl.Location_id = ci.location_id
            inner join DMA.current_microcategories mic
                on ci.microcat_id = mic.microcat_id
                and mic.logical_category = 'Realty.ShortRent'
        ),
    clickstream AS
        (select
            event_date,
            track_id,
            event_no,
            event_timestamp,
            eid,
            cookie,
            cookie_id,
            user_id,
            infm_raw_params,
            infomodel_params,
            search_params,
            params,
            x,
            search_query
        from
            dma.clickstream_search_events
        where 1=1
            -- фильтрация на даты
            and event_date between :first_date and :last_date
            -- and event_week between date_trunc('week', :first_date) and date_trunc('week', :last_date) --@trino
        ),
    events AS (
        select
            t.event_date as event_datetime,
            cast(t.event_date as date) as event_date,
            t.cookie_id,
            t.track_id,
            t.event_no,
            last_value((case when t.eid = 300 then cs.event_no end)) over (partition by t.track_id, t.x order by t.event_no rows between unbounded preceding and current row) as serp_event_no,
            last_value((case when t.eid = 300 then cs.infm_raw_params end)) over (partition by t.track_id, t.x order by t.event_no rows between unbounded preceding and current row) as serp_infm_raw_params,
            last_value((case when t.eid = 300 then cs.infomodel_params end)) over (partition by t.track_id, t.x order by t.event_no rows between unbounded preceding and current row) as serp_infomodel_params,
            last_value((case when t.eid = 300 then cs.search_params end)) over (partition by t.track_id, t.x order by t.event_no rows between unbounded preceding and current row) as serp_search_params,
            last_value((case when t.eid = 300 then cs.params end)) over (partition by t.track_id, t.x order by t.event_no rows between unbounded preceding and current row) as serp_params,
            last_value((case when t.eid = 300 then cs.search_query end)) over (partition by t.track_id, t.x order by t.event_no rows between unbounded preceding and current row) as serp_query,
            t.user_id,
            t.item_id,
            t.x,
            t.x_eid,
            t.eid,
            t.infmquery_id
        from dma.buyer_stream t
            left join str_items as str
                on t.item_id = str.item_id
            left join clickstream as cs
                on t.eid = 300
                and t.track_id = cs.track_id
                and t.event_no = cs.event_no
        where 1=1
            --- фильтрация на даты
            and cast(t.event_date as date) between :first_date and :last_date
            --and cast(t.date as date) between :first_date and :last_date --@trino
             -- оставляем только события поиска, просмотра и бронирования
            and t.eid in (300, 301, 2581)
            -- из событий просмотра и бронирований оставляем только просмотры и бронирования STR-ных айтемов
            and (case when t.eid in (301, 2581) then str.item_id is not null else true end)
        ),
    paid_orders AS (
            select
                distinct StrBooking_id as order_id, CreatedAt as actual_date
            from dds.L_STROrderEventname_StrBooking l
            left join dds.S_STROrderEventname_STREventName s1
                on l.STROrderEventname_id = s1.STROrderEventname_id
            left join dds.S_STROrderEventname_CreatedAt s2
                on l.STROrderEventname_id = s2.STROrderEventname_id
            where STREventName = 'paid'
                and cast(CreatedAt as date) between :first_date and :last_date
            ),
    str_orders AS (
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
            inner join str_items as str
                on s.item_id = str.item_id
                and cast(s.order_create_time as date) between :first_date and :last_date
            left join paid_orders as p
                on s.order_id = p.order_id
        ),
    item_view_sources AS (
        select
            cookie_id,
            item_id,
            event_date,
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
                first_value(t.x_eid) over (partition by t.cookie_id, t.item_id, t.event_date order by t.event_datetime) as x_eid,
                --- следующие поля актуальны только если предыдущее поле x_eid = 300
                first_value(serp_search_params like '%"Сдам"%') over (partition by t.cookie_id, t.item_id, t.event_date order by t.event_datetime) as sdam_flg,
                first_value(serp_search_params like '%"Посуточно"%') over (partition by t.cookie_id, t.item_id, t.event_date order by t.event_datetime) as str_flg,
                first_value(serp_search_params like '%"from"%' and serp_search_params like '%"to"%') over (partition by t.cookie_id, t.item_id, t.event_date order by t.event_datetime) as date_filtered_flg,
                first_value(coalesce(serp_query != '', false)) over (partition by t.cookie_id, t.item_id, t.event_date order by t.event_datetime) as text_query_flg,
                ---
                sum(1) over (partition by t.cookie_id, t.item_id, t.event_date) as item_views_cnt
            from events as t
            where 1=1
                and eid = 301
            ) t
        group by 1, 2, 3
        ),
    user_first_cookie_id AS (
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
        ),
    bookings_first_cookie AS (
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
    min(str.region_id) as region_id,
    min(str.logical_category_id) as logical_category_id,
    min(str.subcategory_id) as subcategory_id,
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
    item_view_sources as iv
    inner join str_items as str
        on iv.item_id = str.item_id
    left join user_first_cookie_id as u
        on iv.cookie_id = u.cookie_id
        and iv.event_date = u.event_date
    left join bookings_first_cookie as bfc
        on iv.cookie_id = bfc.cookie_id
        and iv.item_id = bfc.item_id
        and iv.event_date = bfc.event_date
    left join str_orders as o
        on bfc.user_id = o.buyer_id
        and iv.event_date = o.event_date
        and iv.item_id = o.item_id
group by 1, 2, 3