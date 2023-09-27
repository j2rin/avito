select *
from (
    select  distinct
            l.Logical_Level_Name as value,
            l.Logical_Level as value_id
    from    dma.current_locations l
) _
where value is not null