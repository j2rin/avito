select
    event_date,
    platform_id,
    cookie_id,
    user_id,
    app_version,
    screen_name,
    display_refrash_rate,
    in_time_frames_count,
    jank_frames_count,
    jank_frames_size_avg,
    is_outlier,
    jank_frames_size_total,
    screen_fps_context,
    hitch_time_ratio_sum,
    events_count
from dma.performance_fps f
where event_date::date between :first_date and :last_date
