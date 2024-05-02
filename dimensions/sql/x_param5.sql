select  coalesce(d.microcat_name, 'Undefined') as value,
        d.microcat_id as value_id,
        d.microcat_ext as value_ext_id,
        'x_' || lower(p.level_name) as parent_dimension,
        CASE LOWER(d.level_name) WHEN  'param1' THEN pc.name
             ELSE p.microcat_name
        END AS parent_value,
        CASE LOWER(d.level_name) WHEN 'param1' THEN pc.cat_id
             ELSE d.parent_microcat_id
        END AS parent_value_id,
        CASE LOWER(d.level_name) WHEN 'param1' THEN pc.cat_ext
             ELSE p.microcat_ext
        END AS parent_value_ext_id,
        d.is_active_microcat as is_active
from    dma.current_microcategories d
left join dma.current_microcategories p on p.microcat_id = d.parent_microcat_id
left join DMA.current_categories_new pc on pc.cat_id = d.subcategory_id
where   d.level_name in ('Param5')