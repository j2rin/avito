select  coalesce(d.name, 'Undefined') as value,
        d.cat_id as value_id,
        d.cat_ext as value_ext_id,
        'x_' || CASE p.level_name
            WHEN 'Category' THEN 'category'
            WHEN 'Subcategory' THEN 'subcategory'
            ELSE p.level_name
        END as parent_dimension,
        cast(p.name as varchar(256)) as parent_value,
        d.parent_cat_id as parent_value_id,
        p.cat_ext as parent_value_ext_id,
        d.is_active
from    DMA.current_categories_new d
left join DMA.current_categories_new p on p.cat_id = d.parent_cat_id and p.level_name != 'Root'
where   d.level_name in ('Root', 'Category')