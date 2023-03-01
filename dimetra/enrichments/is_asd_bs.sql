create enrichment is_asd_bs as select
asd.is_asd as is_asd
from :fact_table t
left join (
           select
                asd.user_id,
                (asd.personal_manager_team is not null and asd.user_is_asd_recognised) as is_asd,
                asd.user_group_id as asd_user_group_id,
                c.event_date
            from DMA.am_client_day_versioned asd
            join dict.calendar c on c.event_date between :first_date::date and :last_date::date
            where c.event_date between asd.active_to_date and asd.active_to_date
                and asd.active_from_date <= :last_date::date
                and asd.active_to_date >= :first_date::date
                and asd.user_id in (select :distinct_ item_user_id from :fact_table where __date__ between :first_date and :last_date)
        ) asd on t.item_user_id = asd.user_id and t.__date__ = asd.event_date;