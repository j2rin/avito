with logcat as (select distinct
    logical_category_id, vertical_id
    from dma.current_microcategories)
select event_date, platform_id, logcat.vertical_id, wb.logical_category_id, wb.user_segment_market, cookie_id,
sum(observation_value) observation_value, max(user_id) as user_id
from dma.weighted_buyer_metric wb
left join logcat using(logical_category_id)
where event_date::date between :first_date and :last_date
group by 1,2,3,4,5,6
order by 1,2,3,4,5,6
