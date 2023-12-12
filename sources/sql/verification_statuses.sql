select
    user_id,
    event_time,
    verification_type,
    status,
    source,
    service_source
from dma.verification_statuses
where cast(event_time as date) between :first_date and :last_date
--and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
