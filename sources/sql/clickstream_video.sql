select 
    cs.event_date,
    cs.business_platform,
    cs.user_id,
    cs.microcat_id,
    cs.item_id,
    cs.eid,
    cs.from_page,
    cs.error_text,
    cs.item_add_screen,
    cs.event_chain,
    cs.from_source,
    cs.condition,
    cs.metric_value,
    cm.logical_category_id,
    cm.category_id,
    cm.subcategory_id,
    cm.Param1_microcat_id                                      as param1_id,
    cm.Param2_microcat_id                                      as param2_id,
    cm.Param3_microcat_id                                      as param3_id,
    cm.Param4_microcat_id                                      as param4_id
from DMA.clickstream_video cs
left join DMA.current_microcategories cm using (microcat_id)
where cs.event_date::date between :first_date and :last_date
