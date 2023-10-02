 select ifnull(d.name, 'Undefined')::varchar(256) as value,
        d.logcat_id as value_id,
        d.logcat_ext as value_ext_id,
        'x_' || decode(p.level_name,
               'Vertical',
               'vertical',
               'LogicalCategory',
               'logical_category',
               'LogicalParam1',
               'logical_param1',
               'LogicalParam2',
               'logical_param2')::varchar(64) as
        parent_dimension,
        p.name::varchar(256) as parent_value,
        d.parent_logcat_id as parent_value_id,
        p.logcat_ext as parent_value_ext_id,
        d.is_active
from    DMA.current_logical_categories d
left join DMA.current_logical_categories p on p.logcat_id = d.parent_logcat_id and p.level_name != 'Root'
where   d.level_name in ('LogicalCategory')