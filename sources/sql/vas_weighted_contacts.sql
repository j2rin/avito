with vas_item_contact_price as (
    select
        logcat_id as logical_category_id,
        region,
        xn,
        is_delivery_active,
        event_date as from_date,
        lead(event_date, 1, cast('2099-01-01' as date)) over(partition by logical_category_id, region, xn, is_delivery_active order by event_date) as to_date,
        contact_weight
    from dma.vas_contact_weight
    -- where event_month between date_trunc('month', date(:first_date)) and date_trunc('month', date(:last_date)) -- @trino
)
, buyer_stream_contacts as (
    select
        ss.platform_id,
        ss.event_date,
        ss.cast_event_date,
        ss.cookie_id,
        ss.user_id,
        ss.item_id,
        lc.vertical_id,
        lc.logical_category_id,
        ss.eid,
        ss.x,
        ss.x_eid,
        ss.item_x_type % 2 as item_x_type,
        case when ss.query_id is not null then 'q' else '' end as q,
        ss.rec_engine_id,
        en.Name as engine,
        case
           when cl.region in ('Санкт-Петербург', 'Ленинградская область') then 'Санкт-Петербург и Ленинградская область'
           when cl.region in ('Москва', 'Московская область') then 'Москва и Московская область'
           else 'Регионы'
        end as region,
        case
            when ss.item_vas_xn <= 2 then 2
            when ss.item_vas_xn <= 5 then 5
            when ss.item_vas_xn <= 10 then 10
            when ss.item_vas_xn <= 15 then 15
            when ss.item_vas_xn <= 20 then 20
            else 30
        end as xn,
        IFNULL((item_flags & (1 << 16) > 0), false) as is_delivery_active,
        row_number() over(partition by ss.cookie_id, ss.item_id, cast_event_date order by ss.event_date) as rn
    from (select *, cast(event_date as date) as cast_event_date from dma.buyer_stream) ss
    left join dds.S_EngineRecommendation_Name en
        on en.EngineRecommendation_id = ss.rec_engine_id
    left join dma.current_item ci
        on ss.item_id = ci.item_id
    left join infomodel.current_infmquery_category cic
        on cic.infmquery_id = ci.infmquery_id
    left join dma.current_logical_categories lc
        on cic.logcat_id = lc.logcat_id
    inner join dma.current_locations cl
        on cl.Location_id = ci.Location_id
    where True
        and cast(ss.event_date as date) between :first_date and :last_date
        -- and ss.date between :first_date and :last_date -- @trino
        and ss.is_human_dev
        and ss.eid in (303, 856, 857, 2581, 3005, 3461, 4066, 4600, 4675, 4813, 5942, 6154, 6608, 8814, 10068, 10069, 4198)
)
select
    bsc.platform_id,
    bsc.cast_event_date as event_date,
    bsc.cookie_id,
    bsc.user_id,
    bsc.vertical_id,
    bsc.logical_category_id,
    bsc.eid,
    bsc.x,
    bsc.x_eid,
    bsc.item_x_type,
    bsc.q,
    bsc.rec_engine_id,
    bsc.engine,
    cp.contact_weight as contact_price
from buyer_stream_contacts bsc
inner join vas_item_contact_price cp
    on True
    and bsc.logical_category_id = cp.logical_category_id
    and bsc.xn = cp.xn
    and bsc.region = cp.region
    and bsc.is_delivery_active = cp.is_delivery_active
    and bsc.event_date >= cp.from_date and bsc.event_date < cp.to_date
where rn = 1