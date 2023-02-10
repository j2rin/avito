with entrypoints as (
select 
    eid, 
    user_id,
    event_date,
    event_timestamp,
    is_asd,
    from_page,
    case when from_page in ('chat_list', 'chat', 'stats', 'tariffs') then 'mobile'
         when from_page in ('lk_avito', 'pro_side_bar') then 'mobile' end entrypoint
from dma.jobs_employers_crm_events
)
select 
    eid, 
    user_id,
    event_date,
    event_timestamp,
    is_asd,
    from_page,
    entrypoint,
    row_number() over (partition by user_id, eid order by event_timestamp) rn,
    row_number() over (partition by user_id, eid, entrypoint order by event_timestamp) rn_platform
from entrypoints
where event_date between :first_date and :last_date
