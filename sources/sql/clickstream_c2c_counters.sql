select
    event_no,
    cast(cs.event_date as date) as event_date,
    cs.event_timestamp as event_timestamp,
    cs.cookie_id,
    cs.user_id,
    cl.location_id,
    cs.business_platform as platform_id,
    hp.External_ID as platform,
    cs.item_id,
    cs.event_type_id as eventtype_id,
    cs.eid as eventtype_ext,
    cs.from_page,
    cs.from_page as x_from_page,
    cs.is_human,
    cl.Region as region,
    1 as event_count
from dwhcs.clickstream_canon cs
left join DMA.current_item ci on ci.item_id = cs.item_id
left join dma.current_locations cl on cl.Location_id = ci.location_id
left join dds.H_Platform hp on hp.Platform_id = cs.business_platform
where
    eid in (9651, 4498, 9651, 9752, 9632)
    and event_date::date >= '2023-11-01'
    and event_date::date between :first_date and :last_date
    and from_page in ('c2c_item_card', 'c2c_usp_banner', 'c2c_tinkoff_flow')
