select  coalesce(l.LocationName, 'Undefined') as value,
        l.location_id as value_id,
        l.loc_id as value_ext_id,
        case when pl.level in (1, 2) then 'region' else 'city' end as parent_dimension,
        pl.LocationName as parent_value,
        pl.Location_id as parent_value_id,
        pl.loc_id as parent_value_ext_id,
        l.IsActive as is_active
from    dma.current_locations l
left join dma.current_locations pl on pl.Location_id = l.ParentLocation_id and l.Level = 3
where l.level in (1, 2)