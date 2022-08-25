create fact seller_item_add_finish as
select
    t.item_create_date::date as __date__,
    *
from dma.vo_seller_item_add t
;

create metrics seller_item_add_finish as
select
    sum(case when (duration_sec <= 180 or duration_sec <= 360 and duration_sec > 180 or duration_sec <= 900 and duration_sec > 360 or duration_sec > 900) then 1 end) as cnt_item_added_chains_15min_3_6min_3min_6,
    sum(case when duration_sec > 900 then 1 end) as item_added_chains_15min,
    sum(case when duration_sec <= 360 and duration_sec > 180 then 1 end) as item_added_chains_3_6min,
    sum(case when duration_sec <= 180 then 1 end) as item_added_chains_3min,
    sum(case when duration_sec <= 900 and duration_sec > 360 then 1 end) as item_added_chains_6_15min
from seller_item_add_finish t
;

create metrics seller_item_add_finish_cookie as
select
    sum(case when item_added_chains_15min > 0 then 1 end) as users_with_item_added_chains_15min,
    sum(case when item_added_chains_3_6min > 0 then 1 end) as users_with_item_added_chains_3_6min,
    sum(case when item_added_chains_3min > 0 then 1 end) as users_with_item_added_chains_3min,
    sum(case when item_added_chains_6_15min > 0 then 1 end) as users_with_item_added_chains_6_15min
from (
    select
        cookie_id,
        sum(case when duration_sec > 900 then 1 end) as item_added_chains_15min,
        sum(case when duration_sec <= 360 and duration_sec > 180 then 1 end) as item_added_chains_3_6min,
        sum(case when duration_sec <= 180 then 1 end) as item_added_chains_3min,
        sum(case when duration_sec <= 900 and duration_sec > 360 then 1 end) as item_added_chains_6_15min
    from seller_item_add_finish t
    group by cookie_id
) _
;
