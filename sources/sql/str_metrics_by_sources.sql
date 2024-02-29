-- noinspection SqlNoDataSourceInspectionForFile

with
    str_items as
        (select
            distinct
            ci.item_id,
            cl.region,
            mic.subcategory_name
        from DMA.current_item ci
            inner join DMA.current_locations cl
                on 1=1
                --and cl.region in ('Ставропольский край', 'Новосибирская область', 'Ростовская область', 'Тюменская область', 'Свердловская область', 'Челябинская область', 'Воронежская область', 'Кемеровская область', 'Алтайский край', 'Удмуртия', 'Тульская область', 'Ханты-Мансийский АО')
                and cl.Location_id = ci.location_id
            inner join DMA.current_microcategories mic
                on ci.microcat_id = mic.microcat_id
                --and mic.subcategory_name = 'Квартиры'
                and mic.logical_category = 'Realty.ShortRent'
        ),
    bookings_events as
        (select
            -- есть дубли, далее избавляемся
            t.event_date as event_datetime,
            cast(t.event_date as date) as event_date,
            t.cookie_id,
            t.user_id,
            t.item_id,
            t.x_eid
        from dma.buyer_stream t
            inner join str_items as str
                on t.item_id = str.item_id
                and cast(t.event_date as date) between :first_date and :last_date
                and t.eid = 2581
                -- and action_year between date_trunc('year', date(:first_date)) and date_trunc('year', date(:last_date)) -- @trino
                ),
    bookings_first_x_eid as
        (select
            distinct
            event_date,
            user_id,
            item_id,
            first_value(x_eid) over (partition by event_date, user_id, item_id order by event_datetime) as x_eid
        from
            bookings_events
        where
            x_eid is not null
        ),
    bookings_first_cookie as
        (select
            distinct
            event_date,
            user_id,
            item_id,
            first_value(cookie_id) over (partition by event_date, user_id, item_id order by event_datetime) as cookie_id
        from
            bookings_events
        ),
    day_cookie_user_item_x_eid as
        (select
            t.event_date,
            t.cookie_id,
            t.user_id,
            t.item_id,
            b.x_eid
        from
            bookings_first_cookie as t
            left join bookings_first_x_eid as b
                on t.event_date = b.event_date
                and t.user_id = b.user_id
                and t.item_id = b.item_id
        ),
    str_orders as
        (select
            order_id,
            order_create_time,
            cast(order_create_time as date) as event_date,
            buyer_id,
            item_id,
            amount as str_paid_gmv,
            cast(payout_fee / 100 as float) as str_paid_revenue,
            coalesce(trx_promo_fee, 0) as str_paid_promo_revenue
        from
            dma.short_term_rent_orders
        where 1=1
            and cast(order_create_time as date) between :first_date and :last_date
            and coalesce(order_status, '') not in ('expired', 'rejected_by_host', 'rejected_by_guest', 'unpaid', 'overbooked', 'created')
        )
select
    d.cookie_id,
    d.x_eid,
    str.region,
    str.subcategory_name,
    count(s.order_id) as str_paid_bookings,
    sum(s.str_paid_gmv) as str_paid_gmv,
    sum(s.str_paid_revenue) as str_paid_revenue,
    sum(s.str_paid_promo_revenue) as str_paid_promo_revenue
from
    str_orders as s
    inner join str_items as str
        on s.item_id = str.item_id
    left join day_cookie_user_item_x_eid as d
        on d.event_date = s.event_date
        and s.buyer_id = d.user_id
        and s.item_id = d.item_id
group by 1, 2, 3, 4
;