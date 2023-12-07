select
    cast(cs.event_date as date) as event_date
    , cs.cookie_id
    , cs.user_id
    , cs.platform_id
    , cs.item_id
    , ci.microcat_id
    , ci.location_id
    , case when eventtype_ext = 4413 then 1 end as appcall_item_add_iac_popup_show
    , case when eventtype_ext = 4414 then 1 end as appcall_item_add_iac_popup_accepted
    , case when eventtype_ext = 4099 and appcall_side = 2 then appcall_rating end as appcall_receiver_end_call_rating
    -- Dimensions -----------------------------------------------------------------------------------------------------
    ,cm.vertical_id                                               as vertical_id
    ,cm.logical_category_id                                       as logical_category_id
    ,cm.category_id                                               as category_id
    ,cm.subcategory_id                                            as subcategory_id
    ,cm.Param1_microcat_id                                        as param1_id
    ,cm.Param2_microcat_id                                        as param2_id
    ,cm.Param3_microcat_id                                        as param3_id
    ,cm.Param4_microcat_id                                        as param4_id
    ,case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id
    ,case cl.level when 3 then cl.Location_id end                           as city_id
    ,cl.LocationGroup_id                                          as location_group_id
    ,cl.City_Population_Group                                     as population_group
    ,cl.Logical_Level                                             as location_level_id
from DMA.appcalls_stream cs
left join dma.current_item ci on cs.item_id = ci.item_id
left join DMA.current_microcategories cm on cm.microcat_id = ci.microcat_id
left join DMA.current_locations cl on cl.Location_id = ci.location_id
where True
    and eventtype_ext in (4413, 4414, 4099)
    and cast(cs.event_date as date) between :first_date and :last_date
--    and event_month between date_trunc('month', :first_date) and date_trunc('month', :last_date) -- @trino