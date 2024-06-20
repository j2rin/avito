select 
    adjust_cookie_id as cookie_id,
    adjust_platform as platform_id,
    adjust_event_type,
    cast(installed_at as date) as event_date,
    adjust_tracker,
    adjust_tracker_full,
    location_id
    location_id,
    SPLIT_PART(adjust_tracker_full, '::', 2) as utm_campaign,
    SPLIT_PART(adjust_tracker_full, '::', 3) as utm_content,
    SPLIT_PART(adjust_tracker_full, '::', 4) as utm_term
from dma.adjust_installs
where cast (installed_at as date) between :first_date and :last_date
-- and event_year between date_trunc('year', date(:first_date)) and date_trunc('year', date(:last_date)) -- @trino