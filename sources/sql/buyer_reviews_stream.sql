with orders as (
    select deliveryorder_id,
           count(distinct microcat_id) as count_microcats,
           count(distinct location_id) as count_locations,
           max(microcat_id) as microcat_id,
           max(location_id) as location_id,
           count(distinct microcat_id) > 1 or count(distinct location_id) > 1 as is_mixed_order
    from dma.current_order_item
    group by 1
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
    select track_id, event_no, event_date, event_timestamp, cookie_id, user_id, platform_id, profile_id, review_page_from, review_add_trigger, eid, buyer_review_form_type, has_review, order_status, review_request_send_result,
           is_mixed_order,
    -- Dimensions -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- microcat_dimensions ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    case
        when is_mixed_order then null -- смешанному заказу проставляю null
        else vertical_id -- в других случаях просто забираю категорию айтема
        end                                                                                          as vertical_id,
    case
        when is_mixed_order then null
        else logical_category_id
        end                                                                                          as logical_category_id,
    case
        when is_mixed_order then null
        else category_id
        end                                                                                          as category_id,
    case
        when is_mixed_order then null
        else subcategory_id
        end                                                                                          as subcategory_id,
    case
        when is_mixed_order then null
        else param1_microcat_id
        end                                                                                          as param1_id,
    case
        when is_mixed_order then null
        else param2_microcat_id
        end                                                                                          as param2_id,
    case
        when is_mixed_order then null
        else param3_microcat_id
        end                                                                                          as param3_id,
    case
        when is_mixed_order then null
        else param4_microcat_id
        end                                                                                          as param4_id,
    -- location_dimensions ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    case
        when is_mixed_order then null
        else case level when 3 then ParentLocation_id else cl.Location_id end end               as region_id,
    case
        when is_mixed_order then null
        else case level when 3 then cl.Location_id end end                                      as city_id,
    case
        when is_mixed_order then null
        else LocationGroup_id end                                                               as location_group_id,
    case
        when is_mixed_order then null
        else City_Population_Group end                                                          as population_group,
    case
        when is_mixed_order then null
        else Logical_Level end                                                                  as location_level_id
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
                     is_mixed_order, -- признак goods, поэтому там, где он притянулся null'ом, его разбивка там просто не нужна
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
              --and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
              ) t1
              left join dma.current_microcategories cm on t1.microcat_id = cm.microcat_id
              left join dma.current_locations cl on t1.Location_id = cl.Location_id
          ) data
    left join dma.user_segment_market usm on data.user_id = usm.user_id
                                        and cast(event_timestamp as date) between converting_date and max_valid_date
                                        and data.logical_category_id = usm.logical_category_id
    left join dict.segmentation_ranks sr on sr.logical_category_id = data.logical_category_id and is_default