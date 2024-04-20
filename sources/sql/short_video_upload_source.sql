select 
    video_upload_date event_date,
    upload_page.event_date video_try_date,
    upload_page.user_id,
    upload_page.cookie_id,
    upload_page.platform_id,
    upload_page.from_page,
    video,
    coalesce(upload_page.item_id, cs_chain.item_id) item_id_upload_chain,
    item_video.item_id item_id,
    upload_page.event_chain,
    cm.vertical_id,
    cm.logical_category_id,
    cm.category_id,
    cm.subcategory_id
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
        cast(event_date as date) event_date,
        microcat_id
    from dma.clickstream_video
    where event_date between cast(:first_date as date) and cast(:last_date as date)
        and eid = 6303
    --  and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
) upload_page
left join 
(   
    select  
        External_ID event_chain,
        s.item_id,
        s.microcat_id
    from DMA.item_add_chain_metrics s
        join dds.H_EventChain using (EventChain_id)
    where cast(chain_item_create_time as date) between cast(:first_date as date) and cast(:last_date as date)
    --  and chain_start_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
) cs_chain on cs_chain.event_chain = upload_page.event_chain
left join 
(select 
 	item_id,
 	video,
 	actual_date video_upload_date
 from
    (
        select 
            item_id,
            video,
            cast(actual_date as date) actual_date,
      		row_number() over (partition by video order by actual_date) rn
            from dds.s_item_video
    ) siv 
    where rn = 1 and siv.actual_date between cast(:first_date as date) and cast(:last_date as date)
) item_video on item_video.item_id = coalesce(upload_page.item_id, cs_chain.item_id)
left join DMA.current_microcategories cm on cm.microcat_id = coalesce(upload_page.microcat_id, cs_chain.microcat_id)

