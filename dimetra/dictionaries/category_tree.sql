create dictionary category as
select  cat_id as category_id,
        ifnull(name, 'Undefined') as category
from    DMA.current_categories_new
where   level_name in ('Root', 'Category')
;

create dictionary subcategory as
select  cat_id as subcategory_id,
        ifnull(name, 'Undefined') as subcategory
from    DMA.current_categories_new
where   level_name = 'Subcategory'
;

create dictionary param1 as
select  microcat_id as param1_id,
        ifnull(microcat_name, 'Undefined') as param1
from    dma.current_microcategories
where   level_name = 'Param1'
;

create dictionary param2 as
select  microcat_id as param2_id,
        ifnull(microcat_name, 'Undefined') as param2
from    dma.current_microcategories
where   level_name = 'Param2'
;

create dictionary param3 as
select  microcat_id as param3_id,
        ifnull(microcat_name, 'Undefined') as param3
from    dma.current_microcategories
where   level_name = 'Param3'
;

create dictionary param4 as
select  microcat_id as param4_id,
        ifnull(microcat_name, 'Undefined') as param4
from    dma.current_microcategories
where   level_name = 'Param4'
;
