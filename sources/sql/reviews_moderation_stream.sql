with tmp_reviews_with_status as (
    select 
        Review_id, 
        cast(EventDate as date) as event_date, 
        row_number() over(partition by Review_id,EventType_id  order by EventDate) as rn,
        EventType_id,
        cast(nullif(SPLIT_PART(SPLIT_PART(SPLIT_PART(cs.fraud_code_ids,'[',2),']',1), ',', 1), '') as int) as reason1,
        cast(nullif(SPLIT_PART(SPLIT_PART(SPLIT_PART(cs.fraud_code_ids,'[',2),']',1), ',', 2), '') as int)  as reason2,
        cast(nullif(SPLIT_PART(SPLIT_PART(SPLIT_PART(cs.fraud_code_ids,'[',2),']',1), ',', 3), '') as int)  as reason3 
    from DMA.review_moder_events cs
    where EventType_id in  (169073000001, 169075750001)                         --Событие 2990 - Рейтинги и отзывы / Модерация отзывов / Отзыв не прошел модерацию; --Событие 2989 Рейтинги и отзывы / Модерация отзывов / Отзыв прошел модерацию
            and cast(EventDate as date) >= cast('2023-01-01' as date)
--             and cast(event_year as date) >= cast('2023-01-01' as date) -- @trino
),
tmp_unique_declined_reviews as (
    select *
    from tmp_reviews_with_status
    where rn = 1
)
select
    udr.event_date,
    rpc.platform_id,
    cr.location_id,
    cm.vertical_id,
    cm.category_id,
    cm.subcategory_id,
    cm.logical_category_id,
    cm.microcat_id,
    rpc.cookie_id,
    cr.from_user_id as user_id,
    cr.to_user_id as seller_id,
    reviewstatus,
    cr.stage,
    cr.score,
    cr.photo_count,
    rpc.review_add_trigger,
    rpc.page_from,
    cr.review_id,
    udr.reason1 as fraud_code_reason1,
    udr.reason2 as fraud_code_reason2,
    udr.reason3 as fraud_code_reason3,
    udr.eventtype_id,
    -- Dimensions ----------------------------------------------------------------------------------------------------
    cm.Param1_microcat_id                                        as param1_id,
    cm.Param2_microcat_id                                        as param2_id,
    cm.Param3_microcat_id                                        as param3_id,
    cm.Param4_microcat_id                                        as param4_id,
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
    cl.LocationGroup_id                                          as location_group_id,
    cl.City_Population_Group                                     as population_group,
    cl.Logical_Level                                             as location_level_id
from tmp_unique_declined_reviews as udr
join dma.current_reviews                                as cr on cr.review_id   = udr.review_id
left join /*+jtype(fm)*/ dma.review_params_clickstream  as rpc on cr.review_id   = rpc.review_id
                                                                -- and rpc.create_year is not null -- @trino
left join /*+jtype(h)*/  dma.current_microcategories    as cm  on cr.microcat_id = cm.microcat_id
left join /*+jtype(h)*/  dma.current_locations          as cl  on cr.Location_id = cl.location_id
where udr.event_date between :first_date and :last_date