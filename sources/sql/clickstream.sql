select
    cs.event_date::date                                            as event_date,
    cs.cookie_id,
    cs.user_id,
    cs.platform_id,
    cs.eventtype_id,
    cs.microcat_id,
    cs.location_id,
    cs.item_id is not null                                         as has_item,
    cs.error_code is not null                                      as has_error,
    max(et.EventType_ext)                                          as eid,
    max(cm.vertical_id)                                            as vertical_id,
    max(cm.logical_category_id)                                    as logical_category_id,
    max(cm.category_id)                                            as category_id,
    max(cm.subcategory_id)                                         as subcategory_id,
    max(cm.Param1_microcat_id)                                     as param1_id,
    max(cm.Param2_microcat_id)                                     as param2_id,
    max(cm.Param3_microcat_id)                                     as param3_id,
    max(cm.Param4_microcat_id)                                     as param4_id,
    max(decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id)) as region_id,
    max(decode(cl.level, 3, cl.Location_id, null))                 as city_id,
    max(cl.LocationGroup_id)                                       as location_group_id,
    max(cl.City_Population_Group)                                  as population_group,
    max(cl.Logical_Level)                                          as location_level_id,
    count(*)                                                       as event_count
from DMA.click_stream cs
join DMA.current_eventTypes et using (eventtype_id)
left join DMA.current_microcategories cm using (microcat_id)
left join DMA.current_locations cl using (location_id)
where cs.cookie_id is not null
    and EventType_ext in (
        54,210,212,213,230,299,305,310,333,853,854,856,857,858,2078,2079,2090,2119,2148,2330,
      	2331,2545,2546,2581,2700,2744,2745,2746,2754,2755,2756,2782,2783,2838,2847,2848,2924,2967,3000,3001,
      	3002,3003,3004,3006,3007,3047,3051,3052,3189,3190,3191,3192,3197,3227,3232,3245,3246,3295,3380,3381,3414,3461,
      	3463,3848,3949,4066,4082,4159,4196,4197,4198,4203,4209,4210,4219,4233,4297,4310,4355,4404,4405,4413,
      	4414,4434,4467,4468,4512,4513,4520,4670,4675,4741,4748,5069,5184,5557,5879,5881,5887,3178,6606,6607,
      	6608,2664,2443,5752,5756,6434,6832,6053,4298,3183,4795,7186,7187,8108,8109,8179,4731,8675,8676
		)
	and cs.event_date::date between :first_date and :last_date
group by 1, 2, 3, 4, 5, 6, 7, 8, 9, track_id
