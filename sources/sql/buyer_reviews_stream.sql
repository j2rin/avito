with orders as (
    select coi.deliveryorder_id,
           Microcat_id,
           Location_id
    from dma.current_order_item coi
    join dma.current_order co on coi.deliveryorder_id = co.deliveryorder_id
    where items_qty = 1
    ),
    seller_has_review as (
    select from_user_id,
           min(create_date) as first_date_review
    from dma.current_buyer_reviews
    group by 1
    )
select data.*,
      -- сегмент селлера
      coalesce(usm.user_segment, sr.segment) as user_segment_market
from (
    select track_id, event_no, event_date, event_timestamp, cookie_id, user_id, platform_id, profile_id, review_page_from, review_add_trigger, eid, buyer_review_form_type, has_review, order_status, review_request_send_result, internal_orderid,
    -- Dimensions -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- microcat_dimensions ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    vertical_id,
    logical_category_id,
    category_id,
    subcategory_id,
    Param1_microcat_id as param1_id,
    Param2_microcat_id as param2_id,
    Param3_microcat_id as param3_id,
    Param4_microcat_id as param4_id,
    -- location_dimensions ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    case level when 3 then ParentLocation_id else cl.Location_id end               as region_id,
    case level when 3 then cl.Location_id end                                      as city_id,
    LocationGroup_id                                                               as location_group_id,
    City_Population_Group                                                          as population_group,
    Logical_Level                                                                  as location_level_id
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
                     internal_orderid,
                     coalesce (o.microcat_id, ci.microcat_id)                                                          as microcat_id,
                     coalesce (o.location_id, ci.location_id)                                                          as location_id,
                     coalesce(page_from, 'null')                                                                       as review_page_from,
                     coalesce(case when eid = 8261 then buyer_review_request_type else review_add_trigger end, 'null') as review_add_trigger,
                     coalesce(order_status, 'null')                                                                    as order_status,
                     coalesce(buyer_review_form_type, 'null')                                                          as buyer_review_form_type,
                     coalesce(cast(first_date_review as date) < cast(event_timestamp as date), false)                  as has_review -- если first_date_review is null, значит, селлер ни разу не оставлял отзыв, поэтому has_review = false
              from dma.buyer_reviews_stream brs
              left join orders o
                 on brs.internal_orderid = o.deliveryorder_id and buyer_review_form_type = 'goods'
              -- подтягиваю товары в заказах Goods (их может быть более 1), в STR 1 заказ = 1 айтему (в других проектах наиболее вероятно тоже соотношение 1:1, поэтому ставлю условие только на goods)
              left join dma.current_item ci on brs.item_id = ci.item_id and buyer_review_form_type != 'goods' -- забираю микрокат айтема не из goods (1 заказ = 1 айтем)
              left join seller_has_review cbr on brs.seller_id = from_user_id
              where cast(event_timestamp as date) between :first_date and :last_date
              -- and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
              ) t1
              left join dma.current_microcategories cm on t1.microcat_id = cm.microcat_id
              left join dma.current_locations cl on t1.Location_id = cl.Location_id
          ) data
    left join dma.user_segment_market usm on data.user_id = usm.user_id
                                        and cast(event_timestamp as date) = usm.event_date
                                        and data.logical_category_id = usm.logical_category_id
                                        and usm.reason_code is not null
                                        and usm.event_date between :first_date and :last_date
                                        -- and usm.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
    left join dict.segmentation_ranks sr on sr.logical_category_id = data.logical_category_id and is_default