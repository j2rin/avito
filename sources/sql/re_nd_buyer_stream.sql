select
    ss.platform_id,
    ss.event_date,
    ss.cookie_id,
    ss.user_id,
    ss.realtydevelopment_id,
    ss.item_id,
    ss.eid,
    ss.from_page,
    coalesce(ss.realty_development_flags,0) as realty_development_flags,
    ss.location_id,
    ss.microcat_id,
    ss.node_type, -- все нулл
    ss.catalog_jk_type, -- все нулл
    ss.catalog_jk_action,
    ss.catalog_jk_source,
    ss.catalog_jk_attribute,
    ss.catalog_jk_session,
    ss.objects_count, --items
    case when ss.item_id is not null then 1 else 0 end item_id_not_null,
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
    cl.Logical_Level                                             as location_level_id,
    ss.item_flags,
    ss.phone_view_source
from DMA.re_nd_buyer_stream ss
left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cm on cm.microcat_id = ss.microcat_id
left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations cl on cl.Location_id = ss.location_id
where cast(event_date as date) between :first_date and :last_date
-- and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
