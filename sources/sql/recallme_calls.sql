with clickstream as (
    select 
        cast(event_date as date) as event_date,
        business_platform as platform_id, 
        cookie_id,
  		user_id,
  		item_id,
        microcat_id, 
        recallmerequest_id, 
        item_location_id as location_id, 
        cpaaction_type
    from (
    select *, row_number() over (partition by recallmerequest_id order by event_date desc) rn  
    from dma.recallme_stream
    where recallmerequest_id is not null 
    ) t where rn = 1
)
select  /*+syntactic_join*/
        cs.event_date,
        cs.platform_id, 
        cs.cookie_id,
        cs.user_id,
        cs.item_id,
        cs.microcat_id, 
        cs.recallmerequest_id, 
        cs.location_id, 
        cs.cpaaction_type,
        re.talk_duration_a,
        re.talk_duration_b,
        cast(re.callstarted as date),
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
        cl.Logical_Level   
from dma.recallme_calls re 
join /*+jtype(h)*/ clickstream cs on cs.recallmerequest_id = re.recallmerequest_id
LEFT JOIN /*+jtype(h)*/ DMA.current_microcategories cm on cm.microcat_id   = cs.microcat_id
LEFT JOIN /*+jtype(h)*/ DMA.current_locations       cl ON cl.Location_id   = cs.location_id
where cast(event_date as date) between :first_date and :last_date
