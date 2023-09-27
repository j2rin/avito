select *
from (
    select  distinct l.LocationGroupName as value,
            l.LocationGroup_id as value_id
    from    dma.current_locations l
) _
where value is not null