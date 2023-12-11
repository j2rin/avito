with cond as 
(
  	select 
  	distinct 
  		condition_id,
  		value
  	from DMA.condition_values
)
select 
    cs.event_date,
    cs.business_platform platform_id,
    cs.user_id,
    cs.microcat_id,
    cs.item_id,
    cs.eid,
    cs.from_page,
    cs.error_text,
    cs.item_add_screen,
    cs.event_chain,
    cs.from_source,
    cond.condition_id,
    cs.cookie_id,
    cs.avl_entry_type,
   	case when cs.x_avl_hash is not null then from_big_endian_64(xxhash64(cast(cs.x_avl_hash as varbinary))) end as x_avl_hash,
    cs.metric_value,
    cm.vertical_id,
    cm.logical_category_id,
    cm.category_id,
    cm.subcategory_id,
    cm.Param1_microcat_id                                      as param1_id,
    cm.Param2_microcat_id                                      as param2_id,
    cm.Param3_microcat_id                                      as param3_id,
    cm.Param4_microcat_id                                      as param4_id
from DMA.clickstream_video cs
left join DMA.current_microcategories cm on cm.microcat_id = cs.microcat_id
left join cond on (condition = value)
where cast(cs.event_date as date) between :first_date and :last_date
--and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
