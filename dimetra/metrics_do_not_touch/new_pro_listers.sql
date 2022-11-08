create fact new_pro_listers as
select
    t.event_date::date as __date__,
    *
from dma.new_pro_listers t
;

create metrics new_pro_listers as
select
    sum(case when less_1_month = True and vertical_id != -1 and logical_category_id != -1 then 1 end) as new_pro_listers_less_1_month,
    sum(case when less_1_month = False and vertical_id != -1 and logical_category_id != -1 then 1 end) as new_pro_listers_over_1_month,
    sum(case when vertical_id != -1 and logical_category_id != -1 then 1 end) as new_pro_listers_total,
    sum(case when less_1_month = True and vertical_id = -1 then 1 end) as new_pro_sellers_less_1_month,
    sum(case when less_1_month = False and vertical_id = -1 then 1 end) as new_pro_sellers_over_1_month,
    sum(case when vertical_id = -1 then 1 end) as new_pro_sellers_total,
    sum(case when less_1_month = True and vertical_id != -1 and logical_category_id = -1 then 1 end) as new_pro_sellers_vertical_less_1_month,
    sum(case when less_1_month = False and vertical_id != -1 and logical_category_id = -1 then 1 end) as new_pro_sellers_vertical_over_1_month,
    sum(case when vertical_id != -1 and logical_category_id = -1 then 1 end) as new_pro_sellers_vertical_total
from new_pro_listers t
;

create metrics new_pro_listers_user_logcat as
select
    sum(case when new_pro_listers_less_1_month > 0 then 1 end) as new_pro_listers_less_1_month_uniq,
    sum(case when new_pro_listers_over_1_month > 0 then 1 end) as new_pro_listers_over_1_month_uniq,
    sum(case when new_pro_listers_total > 0 then 1 end) as new_pro_listers_uniq,
    sum(case when new_pro_sellers_less_1_month > 0 then 1 end) as new_pro_sellers_less_1_month_uniq,
    sum(case when new_pro_sellers_over_1_month > 0 then 1 end) as new_pro_sellers_over_1_month_uniq,
    sum(case when new_pro_sellers_total > 0 then 1 end) as new_pro_sellers_uniq,
    sum(case when new_pro_sellers_vertical_less_1_month > 0 then 1 end) as new_pro_sellers_vertical_less_1_month_uniq,
    sum(case when new_pro_sellers_vertical_over_1_month > 0 then 1 end) as new_pro_sellers_vertical_over_1_month_uniq,
    sum(case when new_pro_sellers_vertical_total > 0 then 1 end) as new_pro_sellers_vertical_uniq
from (
    select
        user_id, logical_category_id,
        sum(case when less_1_month = True and vertical_id != -1 and logical_category_id != -1 then 1 end) as new_pro_listers_less_1_month,
        sum(case when less_1_month = False and vertical_id != -1 and logical_category_id != -1 then 1 end) as new_pro_listers_over_1_month,
        sum(case when vertical_id != -1 and logical_category_id != -1 then 1 end) as new_pro_listers_total,
        sum(case when less_1_month = True and vertical_id = -1 then 1 end) as new_pro_sellers_less_1_month,
        sum(case when less_1_month = False and vertical_id = -1 then 1 end) as new_pro_sellers_over_1_month,
        sum(case when vertical_id = -1 then 1 end) as new_pro_sellers_total,
        sum(case when less_1_month = True and vertical_id != -1 and logical_category_id = -1 then 1 end) as new_pro_sellers_vertical_less_1_month,
        sum(case when less_1_month = False and vertical_id != -1 and logical_category_id = -1 then 1 end) as new_pro_sellers_vertical_over_1_month,
        sum(case when vertical_id != -1 and logical_category_id = -1 then 1 end) as new_pro_sellers_vertical_total
    from new_pro_listers t
    group by user_id, logical_category_id
) _
;
