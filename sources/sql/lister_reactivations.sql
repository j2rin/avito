select  mlr.event_date,
        mlr.user_id,
        mlr.location_id,
        clc.logical_category,
        mlr.logical_category_id,
        clc.vertical,
        clc.vertical_id,
        cl.Region as region,
        decode(cl.level, 3, cl.parentlocation_id, cl.location_id) as region_id,
        cl.City as city,
        decode(cl.level, 3, cl.location_id, null) as city_id,
        hash(mlr.user_id, mlr.logical_category_id, mlr.event_date) as reactivation_id
from DMA.lister_reactivations mlr
left join dma.current_locations cl on mlr.location_id = cl.location_id
left join DMA.current_logical_categories clc on mlr.logical_category_id = clc.logical_category_id and clc.level_id = 2
where mlr.user_id not in (select user_id from dma.current_user where IsTest)
    and event_date::date between :first_date and :last_date
