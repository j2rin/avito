with cpx_item_call_price as (
    select 
        item_id,
        actual_date as from_date,
        lead(actual_date, 1, cast('2099-01-01' as date)) over(partition by item_id order by actual_date) as to_date,
        bid_price
    from dma.lmp_cpx_item_call_price
    where cast(actual_date as date) <= :last_date
),
buyer_stream_contacts as (
    select
        ss.platform_id,
        ss.event_date,
        ss.cast_event_date,
        ss.cookie_id,
        ss.user_id,
        ss.item_id,
        cm.logical_category_id,
        ss.eid,
        ss.x,
        ss.x_eid,
        ss.item_x_type % 2 as item_x_type,
        ss.rec_engine_id,
        en.Name as engine,
        case when cp.bid_price is NULL then 0 else cp.bid_price end as call_price,
        row_number() over(partition by ss.cookie_id, ss.item_id, cast_event_date order by ss.event_date) as rn
    from (select *, cast(event_date as date) as cast_event_date from DMA.buyer_stream) ss
    left join DDS.S_EngineRecommendation_Name en ON en.EngineRecommendation_id = ss.rec_engine_id
    left join dma.current_item ci on ss.item_id = ci.item_id
    left join dma.current_microcategories cm on ci.Microcat_id = cm.Microcat_id
    left join cpx_item_call_price cp on ss.item_id=cp.item_id and ss.event_date >= cp.from_date and ss.event_date < cp.to_date
    where True
        and cast(ss.event_date as date) between :first_date and :last_date
        -- and ss.date between :first_date and :last_date -- @trino
        and cm.logical_category = 'Realty.NewDevelopments'
        and ss.is_human_dev
        and eid in (303, 856, 857, 2581, 3005, 4066, 4675, 4813, 5942, 6154, 6608, 10068, 10069, 4198, 3461, 4600)
)
select 
    platform_id,
    cast_event_date as event_date,
    cookie_id,
    user_id,
    logical_category_id,
    eid,
    x,
    x_eid,
    item_x_type,
    rec_engine_id,
    engine,
    call_price
from buyer_stream_contacts
where rn=1
