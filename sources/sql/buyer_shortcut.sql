select
    event_date,
    platform_id,
    cookie_id,
    user_id,
    category_id,
    session_no,
    search,
    iv_s,
    contact_s,
    btc_s
from dma.o_buyer_shortcut
where event_date::date between :first_date and :last_date
