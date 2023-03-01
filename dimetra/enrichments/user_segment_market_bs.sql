select
us.user_segment_market as user_segment_market_bs
from :fact_table t
left join (
            select
                usm.user_id,
                usm.logical_category_id,
                usm.user_segment as user_segment_market,
                c.event_date
            from (
                select
                    user_id,
                    logical_category_id,
                    user_segment,
                    converting_date as from_date,
                    lead(converting_date, 1, '20990101') over(partition by user_id, logical_category_id order by converting_date) as to_date
                from DMA.user_segment_market
                where user_id in (select :distinct_ item_user_id from :fact_table where __date__ between :first_date and :last_date)
                    and converting_date <= :last_date::date
            ) usm
            join dict.calendar c on c.event_date between :first_date::date and :last_date::date
            where c.event_date >= usm.from_date and c.event_date < usm.to_date
                and usm.to_date >= :first_date::date
        ) us on t.item_user_id = us.user_id and us.logical_category_id = t.logical_category_id and t.__date__ = us.event_date
primary_key(logical_category_id);