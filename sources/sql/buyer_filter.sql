select
    event_date,
    platform_id,
    cookie_id,
    user_id,
    search,
    iv_s,
    contact_s,
    btc_s
from dma.o_buyer_filter
where cast(event_date as date) between :first_date and :last_date
-- and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
