select
    coalesce(d.value_name, d.l3_name, 'Undefined') as value,
    d.deliverycat_id as value_id,
    d.deliverycat_ext as value_ext_id,
    'category' as parent_dimension,
    coalesce(p.value_name, d.l2_name, 'Undefined') as parent_value,
    p.deliverycat_id as parent_value_id,
    p.deliverycat_ext as parent_value_ext_id
from dma.current_deliverycategories d
left join dma.current_deliverycategories p on p.deliverycat_id = d.parent_deliverycat_id
where 1=1
    and d.level_id = 3