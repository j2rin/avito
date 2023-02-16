create enrichment microcat_tree as
select
    first(lc.vertical_id, cm.vertical_id, cm_legacy.vertical_id)                              as vertical_id,
    first(lc.logical_category_id, cm.logical_category_id, cm_legacy.subcategory_id)              as logical_category_id,
    lc.logical_param1_id,
    lc.logical_param2_id,
    lc.logcat_id,
    first(cm.category_id, cm_legacy.category_id)                       as category_id,
    first(cm.subcategory_id, cm_legacy.subcategory_id)                 as subcategory_id,
    first(cm.Param1_microcat_id, cm_legacy.Param1_microcat_id)         as param1_id,
    first(cm.Param2_microcat_id, cm_legacy.Param2_microcat_id)         as param2_id,
    first(cm.Param3_microcat_id, cm_legacy.Param3_microcat_id)         as param3_id,
    first(cm.Param4_microcat_id, cm_legacy.Param4_microcat_id)         as param4_id
from :fact_table  t
left join
    (select * from infomodel.current_infmquery_category
     where infmquery_id in (select infmquery_id from :fact_table where __date__ between :first_date and :last_date))
     ic on ic.infmquery_id = t.infmquery_id
left join dma.current_logical_categories lc on lc.logcat_id = ic.logcat_id
left join DMA.current_microcategories cm on cm.microcat_id = ic.microcat_id
left join DMA.current_microcategories cm_legacy on cm_legacy.microcat_id = t.microcat_id
hierarchy (
    (vertical_id, logical_category_id, logical_param1_id, logical_param2_id),
    (category_id, subcategory_id, param1_id, param2_id, param3_id, param4_id)
)
primary_key (infmquery_id, microcat_id)
;