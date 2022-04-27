create enrichment microcat_tree as
select
    first(lc.vertical_id, cm.vertical_id)                     as vertical_id,
    first(lc.logical_category_id, cm.logical_category_id)     as logical_category_id,
    lc.logical_param1_id,
    lc.logical_param2_id,
    cm.category_id                                            as category_id,
    cm.subcategory_id                                         as subcategory_id,
    cm.Param1_microcat_id                                     as param1_id,
    cm.Param2_microcat_id                                     as param2_id,
    cm.Param3_microcat_id                                     as param3_id,
    cm.Param4_microcat_id                                     as param4_id
from :fact_table                               t
left join infomodel.current_infmquery_category ic on ic.infmquery_id = t.infmquery_id
left join dma.current_logical_categories lc on lc.logcat_id = ic.logcat_id
left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cm on cm.microcat_id = t.microcat_id
hierarchy (
    (vertical_id, logical_category_id, logical_param1_id, logical_param2_id),
    (category_id, subcategory_id, param1_id, param2_id, param3_id, param4_id)
);