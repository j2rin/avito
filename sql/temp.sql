create local temp table click_stream_anon_number on commit preserve rows direct as (
    select  weblog_id,
            t.cookie_id,
            event_date,
            eventtype_id,
                 CASE
                 -- Avito.ru:
                 WHEN t.apptype_id IN (2, 500010) THEN 1
                 -- m.Avito.ru:
                 WHEN t.apptype_id = 4 OR (t.apptype_id = 5 and t.clientsideapp_id = 113625250001) THEN 2
                 -- Android:
                 WHEN t.apptype_id IN (5, 500006) AND t.clientsideapp_id = 3 THEN 3
                 -- iOS:
                 WHEN t.apptype_id IN (5, 500006) AND t.clientsideapp_id = 2 THEN 4
               END AS
            platform_id,
            cl.location_id,
            cm.vertical_id,
            cm.category_id,
            cm.subcategory_id,
            cm.logical_category_id,
            session_hash,
            item_id,
            error_code
    from    (
        select  cs.*,
                im.MicroCat_id as item_microcat_id,
                il.Location_id as item_location_id,
                ki.KindOfItem,
                row_number() over (partition by cs.item_id order by im.actual_date desc) rn_m,
                row_number() over (partition by cs.item_id order by il.actual_date desc) rn_l,
                row_number() over (partition by cs.item_id order by ki.actual_date desc) rn_i
        from    dma.click_stream cs
        join    dds.l_item_microcat     im on im.item_id = cs.item_id
        join    dds.l_item_location     il on il.item_id = cs.item_id
        join    dds.S_Item_KindOfItem   ki on ki.item_id = cs.item_id
        where   cs.item_id is not null
            and im.Actual_date <= cs.event_date
            and il.Actual_date <= cs.event_date
            and ki.Actual_date <= cs.event_date
            and cs.event_date::date = '2018-06-19'
    ) t
    join dma.current_microcategories cm on cm.microcat_id = t.item_microcat_id
    join dma.current_locations       cl on cl.location_Id = t.item_location_id
    where   t.rn_m = 1
        and t.rn_l = 1
        and t.rn_i = 1
        and cm.Param1_microcat_id = 3250006 -- Автомобили с пробегом
        and cl.Region IN ('Москва', 'Московская область', 'Санкт-Петербург', 'Ленинградская область')
        and t.KindOfItem = 'Продаю личный автомобиль'
) order by cookie_id segmented by hash(cookie_id) all nodes;


select  
from    