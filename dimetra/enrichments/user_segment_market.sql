create enrichment user_segment_market as select
us.user_segment_market as user_segment_market
from :fact_table t
left join (
            select
                t.user_id,
                t.logical_category_id,
                t.user_segment as user_segment_market,
                c.event_date
            from (
                select
                    user_id,
                    logical_category_id,
                    user_segment,
                    converting_date as from_date,
                    lead(converting_date, 1, '20990101') over(partition by user_id, logical_category_id order by converting_date) as to_date
                from DMA.user_segment_market
                where user_id in (select :distinct_ _user_id_dim from :fact_table where __date__ between :first_date and :last_date)
                    and converting_date <= :last_date::date
            ) t
            join dict.calendar c on c.event_date between :first_date::date and :last_date::date
            where c.event_date >= t.from_date and c.event_date < t.to_date
                and t.to_date >= :first_date::date
        ) us on us.user_id = t._user_id_dim and us.logical_category_id = t.logical_category_id and us.event_date = t.__date__
primary_key(user_id, logical_category_id, __date__);