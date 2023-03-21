create enrichment is_asd as select
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
                and asd.user_id in (select _user_id_dim from _user_id_dim_cte)
        ) asd on asd.user_id = t._user_id_dim and asd.event_date = t.__date__;