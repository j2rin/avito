select  cast(coalesce(d.name, 'Undefined') as varchar(256)) as value,
        d.logcat_id as value_id,
        d.logcat_ext as value_ext_id,
        'x_' || CAST(
              CASE p.level_name
                WHEN 'Vertical' THEN 'vertical'
                WHEN 'LogicalCategory' THEN 'logical_category'
                WHEN 'LogicalParam1' THEN 'logical_param1'
                WHEN 'LogicalParam2' THEN 'logical_param2'
                ELSE p.level_name
              END
              AS VARCHAR(64)
            ) as
        parent_dimension,
        cast(p.name as varchar(256)) as parent_value,
        d.parent_logcat_id as parent_value_id,
        p.logcat_ext as parent_value_ext_id,
        d.is_active
from    DMA.current_logical_categories d
left join DMA.current_logical_categories p on p.logcat_id = d.parent_logcat_id and p.level_name != 'Root'
where   d.level_name in ('Root', 'Vertical')