with orders as (
    select deliveryorder_id, microcat_id, location_id
    from dma.current_order_item
)
select data.*,
      -- сегмент селлера
      coalesce(usm.user_segment, sr.segment) as user_segment_market
from (
    select track_id, event_no, event_date, event_timestamp, cookie_id, user_id, platform_id, profile_id, review_page_from, review_add_trigger, eid, buyer_review_form_type, has_review, order_status, review_request_send_result,
    -- Dimensions -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- microcat_dimensions ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    case
        when count(distinct coalesce(vertical_id, -1)) > 1
            then 500020 -- если в одной строке (одно действие с одним заказом у пользователя) более одной вертикали, значит, это смешанный заказ в гудсах, и мы его помещаем в вертикаль undefined
        else max(vertical_id) -- в других случаях просто забираю категорию айтема
        end                                                                                          as vertical_id,
    case
        when count(distinct coalesce(logical_category_id, -1)) > 1 then 41554500003
        else max(logical_category_id)
        end                                                                                          as logical_category_id,
    case
        when count(distinct coalesce(category_id, -1)) > 1 then 24
        else max(category_id)
        end                                                                                          as category_id,
    case
        when count(distinct coalesce(subcategory_id, -1)) > 1 then null -- в subcategory_id нет значения undefined
        else max(subcategory_id)
        end                                                                                          as subcategory_id,
    case
        when count(distinct coalesce(param1_microcat_id, -1)) > 1 then null
        else max(param1_microcat_id)
        end                                                                                          as param1_id,
    case
        when count(distinct coalesce(param2_microcat_id, -1)) > 1 then null
        else max(param2_microcat_id)
        end                                                                                          as param2_id,
    case
        when count(distinct coalesce(param3_microcat_id, -1)) > 1 then null
        else max(param3_microcat_id)
        end                                                                                          as param3_id,
    case
        when count(distinct coalesce(param4_microcat_id, -1)) > 1 then null
        else max(param4_microcat_id)
        end                                                                                          as param4_id,
    -- location_dimensions ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    case
        when count(distinct coalesce(case level when 3 then ParentLocation_id else cl.Location_id end, -1)) > 1 then null
        else max(case level when 3 then ParentLocation_id else cl.Location_id end) end               as region_id,
    case
        when count(distinct case level when 3 then coalesce(cl.Location_id, -1) end) > 1 then null
        else max(case level when 3 then cl.Location_id end) end                                      as city_id,
    case
        when count(distinct coalesce(LocationGroup_id, -1)) > 1 then null
        else max(LocationGroup_id) end                                                               as location_group_id,
    case
        when count(distinct coalesce(City_Population_Group, '')) > 1 then null
        else max(City_Population_Group) end                                                          as population_group,
    case
        when count(distinct coalesce(Logical_Level, -1)) > 1 then null
        else max(Logical_Level) end                                                                  as location_level_id
          from (
              select
                     track_id,
                     event_no,
                     cast (event_timestamp as date)                                                                    as event_date,
                     event_timestamp,
                     cookie_id,
                     seller_id                                                                                         as user_id,
                     business_platform                                                                                 as platform_id,
                     eid, buyer_id                                                                                     as profile_id,
                     review_request_send_result,
                     coalesce (o.microcat_id, ci.microcat_id)                                                          as microcat_id,
                     coalesce (o.location_id, ci.location_id)                                                          as location_id,
                     coalesce(page_from, 'null')                                                                       as review_page_from,
                     coalesce(case when eid = 8261 then buyer_review_request_type else review_add_trigger end, 'null') as review_add_trigger,
                     coalesce(order_status, 'null')                                                                    as order_status,
                     coalesce(buyer_review_form_type, 'null')                                                          as buyer_review_form_type,
                     cast(max(cast(cbr.buyer_review_id is not null as int)) as boolean)                                   as has_review
              from dma.buyer_reviews_stream brs
              left join orders o
                 on brs.internal_orderid = o.deliveryorder_id and buyer_review_form_type = 'goods'
              -- подтягиваю товары в заказах Goods (их может быть более 1), в STR 1 заказ = 1 айтему (в других проектах наиболее вероятно тоже соотношение 1:1, поэтому ставлю условие только на goods)
              left join dma.current_item ci on brs.item_id = ci.item_id and buyer_review_form_type != 'goods' -- забираю микрокат айтема не из goods (1 заказ = 1 айтем)
              left join dma.current_buyer_reviews cbr on brs.seller_id = from_user_id and create_date < event_timestamp
              where cast(event_timestamp as date) between :first_date and :last_date
              --and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
              group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
              ) t1
              left join dma.current_microcategories cm on t1.microcat_id = cm.microcat_id
              left join dma.current_locations cl on t1.Location_id = cl.Location_id
        group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
          ) data
    left join dma.user_segment_market usm on data.user_id = usm.user_id
                                        and cast(event_timestamp as date) between converting_date and max_valid_date
                                        and data.logical_category_id = usm.logical_category_id
    left join dict.segmentation_ranks sr on sr.logical_category_id = data.logical_category_id and is_default