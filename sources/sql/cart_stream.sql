with /*+ENABLE_WITH_CLAUSE_MATERIALIZATION */
cart_items as 
(
    select distinct item_id 
    from dma.cart_stream 
    where event_date::date between :first_date and :last_date
)
select 
    cs.event_date::date as event_date, 
    cs.cookie_id,
    cs.user_id,
    cs.item_id,
    cs.eid,
    cs.purchase_ext,
    cs.platform_id,
    cs.items_qty,
    cs.status,
    cs.cart_flow_type,
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
    decode(bl.level, 3, bl.ParentLocation_id, bl.Location_id)    as buyer_region_id,
    decode(bl.level, 3, bl.Location_id, null)                    as buyer_city_id,
    bl.LocationGroup_id                                          as buyer_location_group_id,
    bl.City_Population_Group                                     as buyer_population_group,
    bl.Logical_Level                                             as buyer_location_level_id,
    -- seller/item location
    cl.location_id                                               as location_id,
    decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id)    as region_id,
    decode(cl.level, 3, cl.Location_id, null)                    as city_id,
    cl.LocationGroup_id                                          as location_group_id,
    cl.City_Population_Group                                     as population_group,
    cl.Logical_Level                                             as location_level_id --,
---------------------------------------
from dma.cart_stream cs 
left join /*+jtype(h),distrib(l,a)*/ DMA.am_client_day_versioned asd on cs.user_id = asd.user_id and cs.event_date::date between asd.active_from_date and asd.active_to_date
left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cm on cm.microcat_id = cs.microcat_id
left join /*+jtype(h),distrib(l,a)*/ DMA.current_user cu on cu.user_id = cs.user_id
left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations bl on bl.Location_id = cu.location_id
left join /*+jtype(h),distrib(r,l)*/ 
    (
        select item_id, Location_id
        from DMA.current_item 
        where item_id in (select * from cart_items)
    ) ci on ci.item_id = cs.item_id
left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations cl on cl.Location_id = ci.location_id
where cs.event_date::date between :first_date and :last_date
