select  mlr.event_date,
        mlr.user_id,
        mlr.location_id,
        clc.logical_category,
        mlr.logical_category_id,
        clc.vertical,
        clc.vertical_id,
        cl.Region as region,
        case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
        case cl.level when 3 then cl.Location_id end                           as city_id,
        cl.City as city,
        from_big_endian_64(xxhash64(
            to_big_endian_64(coalesce(mlr.user_id, 0)) ||
            to_big_endian_64(coalesce(mlr.logical_category_id, 0)) ||
            to_big_endian_64(cast(date_diff('day', date('2000-01-01'), mlr.event_date) as int))
        )) as reactivation_id
from DMA.lister_reactivations mlr
left join dma.current_locations cl on mlr.location_id = cl.location_id
left join DMA.current_logical_categories clc on mlr.logical_category_id = clc.logical_category_id and clc.level_id = 2
where mlr.user_id not in (select user_id from dma."current_user" where IsTest)
    and cast(event_date as date) between :first_date and :last_date
    -- and mlr.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
