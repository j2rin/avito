with t1 as (
select Review_id, cast(EventDate as date) as event_date, row_number() over(partition by Review_id order by EventDate) as rn,
    cast(nullif(SPLIT_PART(SPLIT_PART(SPLIT_PART(cs.fraud_code_ids,'[',2),']',1), ',', 1), '') as int) as reason1,
    cast(nullif(SPLIT_PART(SPLIT_PART(SPLIT_PART(cs.fraud_code_ids,'[',2),']',1), ',', 2), '') as int)  as reason2,
    cast(nullif(SPLIT_PART(SPLIT_PART(SPLIT_PART(cs.fraud_code_ids,'[',2),']',1), ',', 3), '') as int)  as reason3 
    from DMA.review_moder_events cs
where EventType_id = 169073000001 		                        --Событие 2990 - Рейтинги и отзывы / Модерация отзывов / Отзыв не прошел модерацию
    and cast(EventDate as date) >= cast('2023-01-01' as date)
    -- and cast(event_year as date) >= cast('2023-01-01' as date) -- @trino
),
tmp_declined_reviews_params_clickstream as (
select * from t1 
	where 1=1
	    and rn = 1
	    and (reason1 in (791, 910, 806, 2024) 
		or reason2 in (791, 910, 806, 2024) 
		or reason3 in (791, 910, 806, 2024)) --791 - Ненормативная лексика и оскорбления; 910 - Обвинение в мошенничестве; 806 - Отзыв нарушает правила Авито; 2024 - Упоминание мошенничества
)
select
    event_date,
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
    drpc.reason1 as fraud_code_reason1,
  	drpc.reason2 as fraud_code_reason2,
  	drpc.reason3 as fraud_code_reason3,
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
from tmp_declined_reviews_params_clickstream as drpc
join dma.current_reviews as cr on cr.review_id   = drpc.review_id
left join /*+jtype(fm)*/ dma.review_params_clickstream  as rpc on cr.review_id   = rpc.review_id
left join /*+jtype(h)*/  dma.current_microcategories    as cm  on cr.microcat_id = cm.microcat_id
left join /*+jtype(h)*/  dma.current_locations          as cl  on cr.Location_id = cl.location_id
where event_date between :first_date and :last_date
--and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
