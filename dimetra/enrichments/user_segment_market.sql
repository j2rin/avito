create enrichment user_segment_market as select
first(us.user_segment_market, ls.segment) as user_segment_market
from :fact_table t
left join (
  select user_id,
         converting_date as first_date,
         lead(converting_date, 1, '2030-12-31') over(partition by user_id, logical_category_id order by converting_date) as last_date,
         user_segment as user_segment_market,
         logical_category_id
  from dma.user_segment_market us
  where user_id in (select user_id from :fact_table where event_date = '2022-01-01')
) us
  on us.user_id = t.user_id
  and us.logical_category_id = t.logical_category_id
  and t.__date__ between us.first_date and us.last_date

LEFT JOIN dict.segmentation_ranks ls on ls.logical_category_id = t.logcat_id and ls.is_default
primary_key(user_id, logical_category_id, logcat_id, __date__)
;