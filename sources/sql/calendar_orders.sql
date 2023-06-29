select create_timestamp::date as event_date, 
       orderid,
       sc.buyer_id, 
       sc.item_id, 
       sc.seller_id,
       orderid_dlitelnost, 
       accepted_flg, 
       canceled_flg, 
       canceled_by, 
       minutes_between_creation_and_acceptance, 
       minutes_between_creation_and_cancellation, 
       minutes_between_acceptance_and_cancellation, 
       sc.current_status, 
------ dimensions ----------------------------------------------------
       cm.microcat_id, 
       cl.location_id, 
       cm.vertical_id                                               as vertical_id,
       cm.logical_category_id                                       as logical_category_id,
       cm.category_id                                               as category_id,
       cm.subcategory_id                                            as subcategory_id,
       cm.Param1_microcat_id                                        as param1_id,
       cm.Param2_microcat_id                                        as param2_id, 
       decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id)    as region_id,
       decode(cl.level, 3, cl.Location_id, null)                    as city_id,
       cl.LocationGroup_id                                          as location_group_id,
       cl.City_Population_Group                                     as population_group,
       cl.Logical_Level                                             as location_level_id
from dma.services_calendar_orders sc
left join dma.current_item ci using (item_id)
left join dma.current_microcategories cm using (microcat_id) 
left join dma.current_locations cl using (location_id)
where create_timestamp::date between :first_date::date and :last_date::date
