select
    event_timestamp,
    track_id,
    event_no,
    user_id,
    cookie_id,
    location_id,
    business_platform as platform_id,
    item_id,
    from_page,
    target_page,
    eid,
    app_version,
    component_slug,
    from_page || '_' || target_page as button_name
from dma.auto_select_contacts_buttons
where
    cast(event_timestamp as date) between :first_date and :last_date
    and eid in (8108, 8109)
--  and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
union (
    select
        event_date as event_timestamp,
        track_id,
        event_no,
        user_id,
        cookie_id,
        location_id,
        platform_id,
        item_id,
        from_page,
        target_page,
        eid,
        app_version,
        component_slug,
        from_page || '_' || target_page as button_name
    from dma.auto_select_callback_requests
    where
        cast(event_date as date) between :first_date and :last_date
--      and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
)
