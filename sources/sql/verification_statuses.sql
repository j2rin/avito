select
    user_id,
    event_time,
    verification_type,
    status,
    source,
    service_source
from dma.verification_statuses
where event_time::date between :first_date and :last_date
