with
    items as
        (select
            ci.item_id,
            ci.user_id as seller_user_id,
            case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
            mic.logical_category_id,
            mic.subcategory_id,
            mic.subcategory_name
        from DMA.current_item ci
            inner join DMA.current_locations cl
                on cl.Location_id = ci.location_id
            inner join DMA.current_microcategories mic
                on ci.microcat_id = mic.microcat_id
                and mic.logical_category = 'Realty.NewDevelopments'
        ),
    messenger as
        (select
            m.event_date as event_datetime,
            cast(m.event_date as date) as event_date,
            m.chat_id,
            m.from_user_id,
            m.from_cookie_id,
            m.to_user_id,
            m.chat_item_id as item_id,
            i.seller_user_id,
            m.chat_item_microcat_id as microcat_id
        from
            DMA.messenger_messages as m
            inner join items as i
                on m.chat_item_id = i.item_id
                and cast(m.event_date as date) between :first_date and :last_date
            where 1=1
                and (i.seller_user_id = m.to_user_id or i.seller_user_id != m.from_user_id) --- таким образом, непустое поле m.from_cookie_id будет соответствовать куке баера (OR используем на случай NULL значений)
        ),
    cpa_chats as
        (select
            c.event_date,
            c.chat_id,
            c.user_id as seller_user_id,
            c.cpa_amount,
            c.cpa_amount_net,
            mic.microcat_id is not null as nd_flg
        from
            DMA.cpa_chats as c
            left join DMA.current_microcategories mic
                on c.microcat_id = mic.microcat_id
                and mic.logical_category = 'Realty.NewDevelopments'
        where
            c.is_paid
            and cast(c.event_date as date) between :first_date and :last_date
            -- and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
        ),
    events as
        (select
            d.event_date as event_datetime,
            cast(d.event_date as date) as event_date,
            d.cookie_id,
            d.user_id,
            d.x_eid,
            d.from_page,
            d.item_id,
            d.item_user_id
        from
            dma.buyer_stream as d
            inner join items i
                on d.item_id = i.item_id
                and d.eid = 857
                and cast(d.event_date as date) between :first_date and :last_date
                --and cast(d.date as date) between :first_date and :last_date --@trino
        ),
    events_first_x_eid as
        (select
            distinct
            user_id,
            item_id,
            first_value(x_eid) over (partition by item_id, user_id order by event_datetime) as x_eid
        from
            events
        where
            x_eid is not null
        ),
    messenger_first_buyer_cookie as
        (select
            distinct
            chat_id,
            first_value(from_cookie_id) over (partition by chat_id order by event_datetime) as cookie_id,
            first_value(from_user_id) over (partition by chat_id order by event_datetime) as buyer_id,
            min(seller_user_id) over (partition by chat_id) as seller_id,
            min(item_id) over (partition by chat_id) as item_id
        from messenger
        where
            from_cookie_id is not null --- поле может быть пустым, если сообщение платформенное
        ),
    observations as
        (select
            c.event_date,
            c.chat_id,
            m.item_id,
            c.cpa_amount_net,
            m.cookie_id,
            m.buyer_id as user_id,
            i.region_id,
            i.logical_category_id,
            i.subcategory_id,
            e.x_eid
        from
            cpa_chats as c
            left join messenger_first_buyer_cookie as m
                on c.chat_id = m.chat_id
            left join items as i
                on m.item_id = i.item_id
            left join events_first_x_eid as e
                on e.user_id = m.buyer_id
                and m.item_id = e.item_id
        where 1=1
            and (c.nd_flg or m.chat_id is not null)
        ),
    cpa_chats_final as
        (select
            event_date                                                  as event_date,
            cookie_id                                                   as cookie_id,
            user_id                                                     as user_id,
            item_id                                                     as item_id,
            region_id                                                   as region_id,
            logical_category_id                                         as logical_category_id,
            subcategory_id                                              as subcategory_id,
            x_eid                                                       as x_eid,
            min(null)                                                   as call_source_detailed,
            min('chat')                                                 as channel_type,
            count(chat_id)                                              as cpa_actions,
            cast(coalesce(sum(cpa_amount_net) / 1.2, 0) as decimal)     as cpa_revenue_net_adj
        from
            observations
        group by 1, 2, 3, 4, 5, 6, 7, 8),
    cpa_calls_final as
         (select
             cast(r.action_time as date)                                as event_date,
             r.buyer_cookie_id                                          as cookie_id,
             r.buyer_id                                                 as user_id,
             r.item_id                                                  as item_id,
             coalesce(i.region_id, r.location_id)                       as region_id,
             mic.logical_category_id                                    as logical_category_id,
             mic.subcategory_id                                         as subcategory_id,
             r.x_eid                                                    as x_eid,
             r.call_source_detailed                                     as call_source_detailed,
             min('call')                                                as channel_type,
             count(r.ctcall_id)                                         as cpa_actions,
             cast(coalesce(sum(r.amount_net) / 1.2, 0) as decimal)      as cpa_revenue_net_adj
          from dma.re_nd_cpa_call_source_detailed as r
            left join items as i on r.item_id = i.item_id
            left join DMA.current_microcategories mic
                on r.microcat_id = mic.microcat_id
          where cast(r.action_time as date) between :first_date and :last_date
                and r.income_source is null
                -- and r.action_year between date_trunc('year', date(:first_date)) and date_trunc('year', date(:last_date)) -- @trino
          group by 1, 2, 3, 4, 5, 6, 7, 8, 9)
    select * from cpa_chats_final
    union all
    select * from cpa_calls_final
;

