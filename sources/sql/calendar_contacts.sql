with calendar_type as (
   select bs.user_id, 
   bs.cookie_id,
   bs.item_id, 
   cast(bs.event_date as date) as event_date -- , 
 -----   as calendar_type
from dma.buyer_stream bs
--left join dma.services_active_items_calendar_avito a on bs.item_id = a.item_id and bs.event_date::date = a.event_date 
--left join dma.services_active_items_calendar mp on bs.item_id = mp.item_id and bs.event_date::date = mp.event_date 
where bs.eid = 6154
and   cast(bs.event_date as date) between cast(:first_date as date) and cast(:last_date as date)
)
select event_date, 
       ct.cookie_id,
       ct.user_id, -- контактирующий
       ct.item_id,
       ci.user_id as seller_id,
     --  calendar_type,
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
from calendar_type ct
left join dma.current_item ci using (item_id)
left join dma.current_microcategories cm using (microcat_id) 
left join dma.current_locations cl using (location_id)
--where calendar_type in ('avito', 'moi_profi') -- считаем только контакты по айтемам с определенной принадлежностью. тут не учтутся 
