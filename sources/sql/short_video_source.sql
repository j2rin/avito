with t1
as 
(
select 
    item_id,
    eid,
    from_page,
    event_chain,
    event_date
from dma.clickstream_video cv
where cv.eid = 6303
and error_text is null
and event_date::date between :first_date and :last_date
),
video_dds as 
(
    select *, actual_date::date event_date 
    from dds.s_item_video
)
select 
    t1.event_date,
    cs.business_platform platform_id,
    cs.item_id,
    t1.from_page,
    t1.event_chain,
    video,
    cm.vertical_id,
    cm.logical_category_id,
    cm.category_id,
    cm.subcategory_id,
    cm.Param1_microcat_id                                      as param1_id,
    cm.Param2_microcat_id                                      as param2_id,
    cm.Param3_microcat_id                                      as param3_id,
    cm.Param4_microcat_id                                      as param4_id
from t1  
left join 
(
select business_platform, item_id, event_chain, micro_cat from dwhcs.clickstream_canon
    where eid = 3949
    and event_date between :first_date and :last_date
    and event_chain not ilike '%error%'
) as cs using (event_chain)
left join video_dds siv on cs.item_id = siv.item_id and t1.event_date interpolate previous value siv.event_date
left join DMA.current_microcategories cm on cm.microcat_id = cs.micro_cat


