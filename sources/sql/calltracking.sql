   select ct.launch_id,
        ct.event_date,
        ct.user_id,
        ct.category_id,
        ct.is_attribution,
        ct.phone_plan,
        ct.ct_virtual_phone_plan,
        ct.ct_provider_id,
        ct.phone_location_id,
        ct.calltracking_active,
        ct.calls_total,
        ct.fraud_calls,
        ct.not_fraud_calls,
        ct.received_calls,
        case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
        case cl.level when 3 then cl.Location_id end                           as city_id,
        cl.LocationGroup_id                                       as location_group_id,
        cl.City_Population_Group                                  as population_group,
        cl.Logical_Level                                          as location_level_id,
        c.vertical_id,
        ct.is_item_cpa,
		ct.is_user_cpa,
		ct.cpaaction_type
    from dma.calltracking_metric ct
    LEFT JOIN /*+jtype(h)*/ DMA.current_locations cl ON cl.Location_id   = ct.phone_location_id
    LEFT JOIN /*+jtype(h)*/ DMA.current_categories_new c on c.cat_id = ct.category_id
where cast(event_date as date) between :first_date and :last_date
