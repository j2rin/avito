select
    observation_date,
    cookie_id,
    user_id,
    platform_id,
    platform_version,
    platform_name,
    mobile_app_version,
    network_type,
    screen_name,
    content_type,
    stage_name,
    is_core_content,
    is_appstart,
    events,
    events_p25,
    events_p50,
    events_p75,
    events_p95,
    events_sla,
    duration,
    duration_events,
    exceptions,
    sessions,
    sessions_p25,
    sessions_p50,
    sessions_p75,
    sessions_p95,
    sessions_sla,
    session_duration,
    session_duration_events,
    network_exceptions,
    api_exceptions,
    silent_exceptions,
    unknown_exceptions,
    response,
    was_error_in_screen,
    error_dialog_type,
    screen_is_frequent,
    frequent_screens_enabled,
    max_event_duration,
    max_session_duration,
    vertical
from dma.o_perf_mobile m
where cast(observation_date as date) between :first_date and :last_date
