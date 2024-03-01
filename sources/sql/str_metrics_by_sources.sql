with
    str_items as
        (select
            distinct
            ci.item_id,
            case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
            mic.subcategory_id
        from DMA.current_item ci
            inner join DMA.current_locations cl
                on 1=1
                and cl.Location_id = ci.location_id
            inner join DMA.current_microcategories mic
                on ci.microcat_id = mic.microcat_id
                and mic.logical_category = 'Realty.ShortRent'
        ),
    bookings_events as
        (select
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
                --and cast(t.date as date) between :first_date and :last_date --@trino
                and t.eid = 2581
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
            cast(payout_fee / 100 as decimal) as str_paid_revenue,
            coalesce(trx_promo_fee, 0) as str_paid_promo_revenue
        from
            dma.short_term_rent_orders
        where 1=1
            and cast(order_create_time as date) between :first_date and :last_date
        ),
    paid_orders as
        (select
			distinct StrBooking_id as order_id --, CreatedAt as actual_date
        from dds.L_STROrderEventname_StrBooking l
        left join dds.S_STROrderEventname_STREventName s1
            on l.STROrderEventname_id = s1.STROrderEventname_id
        left join dds.S_STROrderEventname_CreatedAt s2
            on l.STROrderEventname_id = s2.STROrderEventname_id
		where STREventName = 'paid'
		    and cast(CreatedAt as date) between :first_date and :last_date
        )
select
    s.event_date,
    s.buyer_id as user_id,
    d.cookie_id,
    d.x_eid,
    str.region_id,
    str.subcategory_id,
    count(s.order_id) as str_paid_bookings,
    sum(s.str_paid_gmv) as str_paid_gmv,
    sum(s.str_paid_revenue) as str_paid_revenue,
    sum(s.str_paid_promo_revenue) as str_paid_promo_revenue
from
    str_orders as s
    inner join str_items as str
        on s.item_id = str.item_id
    inner join paid_orders as p
        on s.order_id = p.order_id
    left join day_cookie_user_item_x_eid as d
        on d.event_date = s.event_date
        and s.buyer_id = d.user_id
        and s.item_id = d.item_id
group by 1, 2, 3, 4, 5, 6
;