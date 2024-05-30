select /*+syntactic_join*/
    event_date,
    user_id,
    uiad.location_id,
    -- Dimensions -----------------------------------------------------------------------
    cm.vertical_id               as vertical_id,
    cm.logical_category_id       as logical_category_id,
    cm.category_id               as category_id,
    cm.subcategory_id            as subcategory_id,
    cm.Param1_microcat_id        as param1_id,
    cm.Param2_microcat_id        as param2_id,
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,

    unique_items,
    item_7days,
    item_14days,
    item_28days 

from DMA.user_item_active_days uiad

left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cm on cm.microcat_id = uiad.microcat_id

left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations cl on cl.Location_id = uiad.location_id

where uiad.event_date between :first_date and :last_date
