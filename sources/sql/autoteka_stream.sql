select
    track_id,
    event_no,
    event_date,
    cookie_id,
    user_id,
    additionalcookie_id,
    autotekauser_id,
    is_authorized,
    searchkey,
    searchtype,
    item_id,
    platenumber,
    vin,
    autoteka_platform_id,
    autotekaorder_id,
    reports_count,
    amount,
    payment_method,
    user_created_at,
    is_new_user,
    b_track_id,
    b_event_no,
    b_event_date,
    f_track_id,
    f_event_no,
    f_event_date,
    funnel_stage_id,
    utm_campaign,
    utm_source,
    utm_medium,
    platform_id,
    autoteka_cookie_id,
    is_pro,
    utm_content,
    utm_term
from dma.autoteka_stream
where event_date::date between :first_date and :last_date