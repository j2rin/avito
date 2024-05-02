select
    cast(ds.event_date as date) as event_date,
    ds.cookie_id,
    ds.user_id,
    ds.item_id,
    ds.eid,
    ds.purchase_ext,
    ds.platform_id,
    ds.items_qty,
    ds.status,
    ds.cart_flow_type,
    ds.is_cart,
---------- DIMENTIONS ------------------
    -- about item
    cm.vertical_id                                              as vertical_id,
    cm.logical_category_id                                      as logical_category_id,
    cm.category_id                                              as category_id,
    cm.subcategory_id                                           as subcategory_id,
    cm.Param1_microcat_id                                       as param1_id,
    cm.Param2_microcat_id                                       as param2_id,
    cm.Param3_microcat_id                                       as param3_id,
    cm.Param4_microcat_id                                       as param4_id,
    case
        when bl.location_id <> cl.location_id then true
        else false
    end                                                         as is_intercity,
    -- asd
    (asd.personal_manager_team is not null and asd.user_is_asd_recognised) as is_asd,
    asd.user_group_id                                           as asd_user_group_id,
    -- buyer_location
    bl.location_id                                               as buyer_location_id,
    case bl.level when 3 then bl.ParentLocation_id else bl.Location_id end as buyer_region_id,
    case bl.level when 3 then bl.Location_id end                           as buyer_city_id,
    bl.LocationGroup_id                                          as buyer_location_group_id,
    bl.City_Population_Group                                     as buyer_population_group,
    bl.Logical_Level                                             as buyer_location_level_id,
    -- seller/item location
    cl.location_id                                               as location_id,
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
    cl.LocationGroup_id                                          as location_group_id,
    cl.City_Population_Group                                     as population_group,
    cl.Logical_Level                                             as location_level_id --,
---------------------------------------
from dma.delivery_stream ds
left join /*+jtype(h),distrib(l,a)*/ DMA.am_client_day_versioned asd on ds.user_id = asd.user_id and cast(ds.event_date as date) between asd.active_from_date and asd.active_to_date
left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cm on cm.microcat_id = ds.microcat_id
left join /*+jtype(h),distrib(r,l)*/ DMA."current_user" cu on cu.user_id = ds.user_id
left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations bl on bl.Location_id = cu.location_id
left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations cl on cl.Location_id = ds.location_id
where cast(ds.event_date as date) between :first_date and :last_date
    -- and ds.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino

