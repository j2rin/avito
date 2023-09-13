select
	uc.user_id,
	uc.event_date,
	clc.vertical_id,
	uc.logical_category_id,
	uc.category_id,
	uc.subcategory_id,
	uc.region_id,
	uc.city_id
from DMA.user_cohort uc
join DMA.current_logical_categories clc
	on uc.logical_category_id = clc.logical_category_id
where uc.user_id not in (select user_id from dma."current_user" where isTest)
    and cast(uc.event_date as date) between :first_date and :last_date
