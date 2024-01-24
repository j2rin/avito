with entrypoints as (
select
    platform,
    eid,
    user_id,
    event_date,
    event_timestamp,
    is_asd,
    from_page,
    case when from_page in ('chat_list', 'chat', 'stats', 'tariffs') then 'mobile'
         when coalesce(from_page, 'lk_avito') in ('lk_avito', 'pro_side_bar') then 'web' else 'web' end entrypoint,
    row_number() over (partition by user_id, eid order by event_timestamp) rn
from dma.jobs_employers_crm_events
--where event_year is not null --@trino
)
select
    platform,
    eid,
    user_id,
    event_date,
    event_timestamp,
    is_asd,
    from_page,
    entrypoint,
    rn
from entrypoints
where event_date between :first_date and :last_date
