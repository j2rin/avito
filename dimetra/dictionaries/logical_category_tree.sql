create dictionary vertical as
select  logcat_id as vertical_id,
        name as vertical
from    dma.current_logical_categories
where   level_name in ('Vertical', 'Root')
;

create dictionary logical_category as
select  logcat_id as logical_category_id,
        name as logical_category
from    dma.current_logical_categories
where   level_name = 'LogicalCategory'
;

create dictionary logical_param1 as
select  logcat_id as logical_param1_id,
        name as logical_param1
from    dma.current_logical_categories
where   level_name = 'LogicalParam1'
;

create dictionary logical_param2 as
select  logcat_id as logical_param2_id,
        name as logical_param2
from    dma.current_logical_categories
where   level_name = 'LogicalParam2'
;
