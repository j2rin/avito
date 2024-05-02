select
    event_date,
    cookie_id,
    user_id,
    platform_id,
    eid,
    screen_name,
    events_count,
    performance_metric_event_duration_sum,
    native_heap_size_sum,
    java_heap_size_sum,
    code_size_sum,
    stack_size_sum,
    graphics_size_sum,
    private_other_size_sum,
    blocking_gc_count,
    blocking_gc_time_sum,
    gc_count,
    gc_time_sum,
    network_error_type,
    network_error_sub_type,
    mobile_app_start_type
from dma.perf_click_stream_counters c
where cast(event_date as date) between :first_date and :last_date
-- and event_month between date_trunc('month', :first_date) and date_trunc('month', :last_date) -- @trino
