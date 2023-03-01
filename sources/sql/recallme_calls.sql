with cs as (
    select 
        event_date::date,
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
        re.callstarted::date,
        -- Dimensions -----------------------------------------------------------------------------------------------------
        cm.vertical_id                                               as vertical_id,
        cm.logical_category_id                                       as logical_category_id,
        cm.category_id                                               as category_id,
        cm.subcategory_id                                            as subcategory_id,
        cm.Param1_microcat_id                                        as param1_id,
        cm.Param2_microcat_id                                        as param2_id,
        cm.Param3_microcat_id                                        as param3_id,
        cm.Param4_microcat_id                                        as param4_id,
        decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id)    as region_id,
        decode(cl.level, 3, cl.Location_id, null)                    as city_id,
        cl.LocationGroup_id                                          as location_group_id,
        cl.City_Population_Group                                     as population_group,
        cl.Logical_Level   
from dma.recallme_calls re 
join /*+jtype(h)*/ cs using(recallmerequest_id)
LEFT JOIN /*+jtype(h)*/ DMA.current_microcategories cm on cm.microcat_id   = cs.microcat_id
LEFT JOIN /*+jtype(h)*/ DMA.current_locations       cl ON cl.Location_id   = cs.location_id
where event_date::date between :first_date and :last_date
