select
    hash(buyer_id, cd.item_id) as deal_id,
    chat_id,
    buyer_id,
    seller_id,
    cd.item_id,
    contactmethod,
    null as deal_confirmation_source,
    dealconfirmationstate,
    event_time,
    -- Dimensions -----------------------------------------------------------------------------------------------------
    cm.vertical_id                                               as vertical_id,
    cm.logical_category_id                                       as logical_category_id,
    cm.category_id                                               as category_id,
    cm.subcategory_id                                            as subcategory_id,
    cm.Param1_microcat_id                                        as param1_id,
    cm.Param2_microcat_id                                        as param2_id,
    cm.Param3_microcat_id                                        as param3_id,
    cm.Param4_microcat_id                                        as param4_id,
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
    cl.LocationGroup_id                                          as location_group_id,
    cl.City_Population_Group                                     as population_group,
    cl.Logical_Level                                             as location_level_id
from dma.confirmation_deals cd
left join dma.current_item                      as ci on cd.item_id = ci.item_id
left join dma.current_microcategories           as cm on ci.microcat_id = cm.microcat_id
left join dma.current_locations                 as cl on ci.location_id = cl.location_id
where cast(cd.event_time as date) between :first_date and :last_date
    and cast(cd.event_time as date) <= date('2023-01-16')  -- c 17 января берем данные из другой витрины
    and not seller_id is null

union all

select
    deal_id,
    chat_id,
    buyer_id,
    seller_id,
    cd.item_id,
    contact_method as contactmethod,
    deal_confirmation_source,
    dealconfirmationstate,
    event_time,
    -- Dimensions -----------------------------------------------------------------------------------------------------
    cm.vertical_id                                               as vertical_id,
    cm.logical_category_id                                       as logical_category_id,
    cm.category_id                                               as category_id,
    cm.subcategory_id                                            as subcategory_id,
    cm.Param1_microcat_id                                        as param1_id,
    cm.Param2_microcat_id                                        as param2_id,
    cm.Param3_microcat_id                                        as param3_id,
    cm.Param4_microcat_id                                        as param4_id,
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
    cl.LocationGroup_id                                          as location_group_id,
    cl.City_Population_Group                                     as population_group,
    cl.Logical_Level                                             as location_level_id
from dma.new_confirmation_deals cd
left join dma.current_item                      as ci on cd.item_id = ci.item_id
left join dma.current_microcategories           as cm on ci.microcat_id = cm.microcat_id
left join dma.current_locations                 as cl on ci.location_id = cl.location_id
where cast(cd.event_time as date) between :first_date and :last_date

union all

select 
    deal_id,
    chat_id,
    buyer_id,
    seller_id, 
    ns.item_id,
    contact_method as contactmethod,
    deal_confirmation_source,
    state as dealconfirmationstate, 
    event_timestamp as event_time,
    -- Dimensions -----------------------------------------------------------------------------------------------------
    cm.vertical_id                                               as vertical_id,
    cm.logical_category_id                                       as logical_category_id,
    cm.category_id                                               as category_id,
    cm.subcategory_id                                            as subcategory_id,
    cm.Param1_microcat_id                                        as param1_id,
    cm.Param2_microcat_id                                        as param2_id,
    cm.Param3_microcat_id                                        as param3_id,
    cm.Param4_microcat_id                                        as param4_id,
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
    cl.LocationGroup_id                                          as location_group_id,
    cl.City_Population_Group                                     as population_group,
    cl.Logical_Level                                             as location_level_id
from  DMA.deals_confirmation_new_service ns
left join dma.current_item                      as ci on ns.item_id = ci.item_id
left join dma.current_microcategories           as cm on ci.microcat_id = cm.microcat_id
left join dma.current_locations                 as cl on ci.location_id = cl.location_id
where cast(ns.event_timestamp as date) between :first_date and :last_date