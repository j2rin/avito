select 
    video_upload_date event_date,
    upload_page.event_date video_try_date,
    cs_chain.user_id,
    cs_chain.cookie_id,
    cs_chain.platform_id,
    cs_chain.from_page,
    video,
    coalesce(upload_page.item_id, cs_chain.item_id) item_id_upload_chain,
    item_video.item_id item_video_id,
    upload_page.event_chain,
    cm.vertical_id,
    cm.logical_category_id,
    cm.category_id,
    cm.subcategory_id,
    cm.Param1_microcat_id                                      as param1_id,
    cm.Param2_microcat_id                                      as param2_id,
    cm.Param3_microcat_id                                      as param3_id,
    cm.Param4_microcat_id                                      as param4_id
from 
(
    select 
        user_id,
        cookie_id,
        business_platform platform_id,
        item_id,
        from_page,
        event_chain,
        error_text,
        cast(event_date as date) event_date
    from dma.clickstream_video
    where event_date between cast(:first_date as date) - 2 and cast(:last_date as date) - 2
        and eid = 6303
) upload_page
left join 
(   
    select 
        item_id,
        event_chain
    from dwhcs.clickstream_canon 
    where event_date between cast(:first_date as date) - 2 and cast(:last_date as date) - 2
        and eid = 3949
) cs_chain using (event_chain)
left join 
(select * from
    (
        select 
            item_id,
            video,
            cast(actual_date as date) video_upload_date
            from dds.s_item_video
            limit 1 over (partition by video order by actual_date)
    ) siv 
    where siv.video_upload_date between cast(:first_date as date) - 2 and cast(:last_date as date) - 2
) item_video on item_video.item_id = upload_page.item_id or item_video.item_id = cs_chain.item_id
left join DMA.current_microcategories cm on cm.microcat_id = cs.microcat_id