create dictionary region as
select  location_id as region_id,
        LocationName as region
from    dma.current_locations l
where   level in (1, 2)
;

create dictionary city as
select  location_id as city_id,
        LocationName as city
from    dma.current_locations l
where   level = 3
;

create dictionary location_group as
select distinct
    LocationGroup_id as location_group_id,
    LocationGroupName as location_group
from dma.current_locations
where LocationGroup_id is not null
;

create dictionary population_group as
select distinct
    City_Population_Group as population_group
from dma.current_locations
where City_Population_Group is not null
;

create dictionary location_level as
select distinct
    Logical_Level as location_level_id,
    Logical_Level_Name as location_level
from dma.current_locations
where Logical_Level is not null
;
