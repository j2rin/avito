with cpx_item_click_price as (
    select 
        item_id,
        event_date as from_date,
        lead(event_date, 1, cast('2099-01-01' as date)) over(partition by item_id order by event_date) as to_date,
        price
    from dma.current_cpx_prices
    where cast(event_date as date) <= :last_date
),
buyer_stream_contacts as (
    select
        ss.platform_id,
        ss.event_date,
        ss.cast_event_date,
        ss.cookie_id,
        ss.user_id,
        ss.item_id,
        cm.vertical_id,
        cm.logical_category_id,
        ss.eid,
        ss.x,
        ss.x_eid,
        ss.item_x_type % 2 as item_x_type,
        case when ss.query_id is not null then 'q' else '' end as q,
        ss.rec_engine_id,
        en.Name as engine,
        case when cp.price is NULL then 0 else cp.price end as click_price,
        row_number() over(partition by ss.cookie_id, ss.item_id, cast_event_date order by ss.event_date) as rn
    from (select *, cast(event_date as date) as cast_event_date from DMA.buyer_stream) ss
    left join DDS.S_EngineRecommendation_Name en ON en.EngineRecommendation_id = ss.rec_engine_id
    left join dma.current_item ci on ss.item_id = ci.item_id
    left join dma.current_microcategories cm on ci.Microcat_id = cm.Microcat_id
    left join cpx_item_click_price cp on ss.item_id=cp.item_id and ss.event_date >= cp.from_date and ss.event_date < cp.to_date
    where True
        and cast(ss.event_date as date) between :first_date and :last_date
        -- and ss.date between :first_date and :last_date -- @trino
        and cm.vertical = 'Goods'
        and ss.is_human_dev
        and eid = 301
)
select 
    platform_id,
    cast_event_date as event_date,
    cookie_id,
    user_id,
    vertical_id,
    logical_category_id,
    eid,
    x,
    x_eid,
    item_x_type,
    q,
    rec_engine_id,
    engine,
    click_price
from buyer_stream_contacts
where rn = 1
