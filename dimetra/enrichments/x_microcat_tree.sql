create enrichment x_microcat_tree as select
    cmx.vertical_id                                              as x_vertical_id,
    cmx.logical_category_id                                      as x_logical_category_id,
    cmx.category_id                                              as x_category_id,
    cmx.subcategory_id                                           as x_subcategory_id,
    cmx.Param1_microcat_id                                       as x_param1_id,
    cmx.Param2_microcat_id                                       as x_param2_id,
    cmx.Param3_microcat_id                                       as x_param3_id,
    cmx.Param4_microcat_id                                       as x_param4_id
from :fact_table t
left join DMA.current_microcategories cmx on cmx.microcat_id = t.x_microcat_id
;