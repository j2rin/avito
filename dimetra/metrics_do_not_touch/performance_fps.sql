create fact performance_fps as
select
    t.event_date::date as __date__,
    *
from dma.performance_fps t
;

create metrics performance_fps as
select
    sum(case when is_outlier = False then ifnull(in_time_frames_count, 0) + ifnull(jank_frames_count, 0) end) as all_frames,
    sum(case when is_outlier = False then in_time_frames_count end) as in_time_frames,
    sum(case when is_outlier = False then jank_frames_count end) as jank_frames,
    sum(case when is_outlier = False then jank_frames_size_total end) as jank_frames_size_total
from performance_fps t
;

create metrics performance_fps_cookie as
select
    sum(case when all_frames > 0 then 1 end) as user_all_frames,
    sum(case when jank_frames > 0 then 1 end) as user_jank_frames
from (
    select
        cookie_id,
        sum(case when is_outlier = False then ifnull(in_time_frames_count, 0) + ifnull(jank_frames_count, 0) end) as all_frames,
        sum(case when is_outlier = False then jank_frames_count end) as jank_frames
    from performance_fps t
    group by cookie_id
) _
;
