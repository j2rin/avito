create fact perf_video_metrics as
select
    t.event_date::date as __date__,
    *
from dma.perf_video_metrics t
;

create metrics perf_video_metrics as
select
    sum(playback_stalls_count) as playback_stalls_count,
    sum(case when playback_stalls_count is not null then 1 end) as playback_stalls_events,
    sum(skipped_frames_count) as skipped_frames_count,
    sum(case when skipped_frames_count is not null then 1 end) as skipped_frames_events,
    sum(time_to_display_video) as time_to_display_video_sum,
    sum(time_to_prepare_video) as time_to_prepare_video_sum,
    sum(case when eid = 6591 then 1 end) as video_playback_error_events,
    sum(case when eid = 6590 then 1 end) as video_playback_events,
    sum(case when eid = 6588 then 1 end) as video_startup_events
from perf_video_metrics t
;

create metrics perf_video_metrics_cookie as
select
    sum(case when playback_stalls_events > 0 then 1 end) as playback_stalls_users,
    sum(case when skipped_frames_events > 0 then 1 end) as skipped_frames_users,
    sum(case when video_playback_error_events > 0 then 1 end) as video_playback_error_users
from (
    select
        cookie_id,
        sum(case when playback_stalls_count is not null then 1 end) as playback_stalls_events,
        sum(case when skipped_frames_count is not null then 1 end) as skipped_frames_events,
        sum(case when eid = 6591 then 1 end) as video_playback_error_events
    from perf_video_metrics t
    group by cookie_id
) _
;
