create enrichment is_asd as
select
    aus.user_id is not null as is_asd
from :fact_table t
left join DMA.am_client_day aus
    on aus.user_id = t.user_id
    and aus.event_date = t.event_date
    and aus.personal_manager_team is not Null
    and aus.user_is_asd_recognised;