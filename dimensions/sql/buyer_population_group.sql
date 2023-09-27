select *
from (
    select  distinct
            l.City_Population_Group as value
    from    dma.current_locations l
) _
where value is not null