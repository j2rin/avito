select
    track_id,
    event_no,
    event_date,
    cookie_id,
    user_id,
    platform_id,
    eid,
    time_to_prepare_video,
    time_to_display_video,
    skipped_frames_count,
    playback_stalls_count
from dma.perf_video_metrics
where cast(event_date as date) between :first_date and :last_date
    -- and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
