select  ifnull(d.microcat_name, 'Undefined') as value,
        d.microcat_id as value_id,
        d.microcat_ext as value_ext_id,
        'x_' || lower(p.level_name) as parent_dimension,
        decode(lower(d.level_name), 'param1', pc.name, p.microcat_name) as parent_value,
        decode(lower(d.level_name), 'param1', pc.cat_id, d.parent_microcat_id) as parent_value_id,
        decode(lower(d.level_name), 'param1', pc.cat_ext, p.microcat_ext) as parent_value_ext_id,
        d.is_active_microcat as is_active
from    dma.current_microcategories d
left join dma.current_microcategories p on p.microcat_id = d.parent_microcat_id
left join DMA.current_categories_new pc on pc.cat_id = d.subcategory_id
where   d.level_name in ('Param1')