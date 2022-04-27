create fact image as
select
    t.cookie_id,
    t.event_date,
    t.observation_name,
    t.observation_value,
    t.participant_id
from dma.vo_image t
;

create metrics image as
select
    sum(case when observation_name = 'image_draw_appstart_duration' then observation_value end) as cnt_image_draw_appstart_duration,
    sum(case when observation_name = 'image_draw_appstart_duration_events' then observation_value end) as cnt_image_draw_appstart_duration_events,
    sum(case when observation_name = 'image_draw_appstart_events' then observation_value end) as cnt_image_draw_appstart_events,
    sum(case when observation_name in ('image_draw_appstart_events', 'image_draw_appstart_exceptions') then observation_value end) as cnt_image_draw_appstart_events_exceptions,
    sum(case when observation_name = 'image_draw_appstart_events_p25' then observation_value end) as cnt_image_draw_appstart_events_p25,
    sum(case when observation_name = 'image_draw_appstart_events_p50' then observation_value end) as cnt_image_draw_appstart_events_p50,
    sum(case when observation_name = 'image_draw_appstart_events_p75' then observation_value end) as cnt_image_draw_appstart_events_p75,
    sum(case when observation_name = 'image_draw_appstart_events_p95' then observation_value end) as cnt_image_draw_appstart_events_p95,
    sum(case when observation_name = 'image_draw_duration' then observation_value end) as cnt_image_draw_duration,
    sum(case when observation_name = 'image_draw_duration_events' then observation_value end) as cnt_image_draw_duration_events,
    sum(case when observation_name = 'image_draw_events' then observation_value end) as cnt_image_draw_events,
    sum(case when observation_name in ('image_draw_events', 'image_draw_exceptions') then observation_value end) as cnt_image_draw_events_exceptions,
    sum(case when observation_name = 'image_draw_events_p25' then observation_value end) as cnt_image_draw_events_p25,
    sum(case when observation_name = 'image_draw_events_p50' then observation_value end) as cnt_image_draw_events_p50,
    sum(case when observation_name = 'image_draw_events_p75' then observation_value end) as cnt_image_draw_events_p75,
    sum(case when observation_name = 'image_draw_events_p95' then observation_value end) as cnt_image_draw_events_p95,
    sum(case when observation_name = 'image_load_duration' then observation_value end) as cnt_image_load_duration,
    sum(case when observation_name = 'image_load_duration_events' then observation_value end) as cnt_image_load_duration_events,
    sum(case when observation_name = 'image_load_events' then observation_value end) as cnt_image_load_events,
    sum(case when observation_name in ('image_load_events', 'image_load_events_exceptions') then observation_value end) as cnt_image_load_events_exceptions,
    sum(case when observation_name = 'image_load_events_p25' then observation_value end) as cnt_image_load_events_p25,
    sum(case when observation_name = 'image_load_events_p50' then observation_value end) as cnt_image_load_events_p50,
    sum(case when observation_name = 'image_load_events_p75' then observation_value end) as cnt_image_load_events_p75,
    sum(case when observation_name = 'image_load_events_p95' then observation_value end) as cnt_image_load_events_p95,
    sum(case when observation_name in ('image_draw_appstart_core_content_exceptions', 'image_draw_core_content_exceptions', 'image_load_core_content_exceptions') then observation_value end) as image_any_core_exceptions,
    sum(case when observation_name in ('image_draw_appstart_exceptions', 'image_draw_exceptions', 'image_load_exceptions') then observation_value end) as image_any_exceptions,
    sum(case when observation_name = 'image_draw_appstart_core_content_exceptions' then observation_value end) as image_draw_appstart_core_exceptions,
    sum(case when observation_name = 'image_draw_appstart_exceptions' then observation_value end) as image_draw_appstart_exceptions,
    sum(case when observation_name = 'image_draw_core_content_exceptions' then observation_value end) as image_draw_core_exceptions,
    sum(case when observation_name = 'image_draw_exceptions' then observation_value end) as image_draw_exceptions,
    sum(case when observation_name = 'image_load_core_content_exceptions' then observation_value end) as image_load_core_exceptions,
    sum(case when observation_name = 'image_load_exceptions' then observation_value end) as image_load_exceptions
from image t
;

create metrics image_participant_id as
select
    sum(case when image_any_core_exceptions > 0 then 1 end) as user_image_core_exceptions,
    sum(case when image_draw_appstart_exceptions > 0 then 1 end) as user_image_draw_appstart_exceptions,
    sum(case when image_draw_exceptions > 0 then 1 end) as user_image_draw_exceptions,
    sum(case when image_any_exceptions > 0 then 1 end) as user_image_exceptions,
    sum(case when image_load_exceptions > 0 then 1 end) as user_image_load_exceptions
from (
    select
        cookie_id, participant_id,
        sum(case when observation_name in ('image_draw_appstart_core_content_exceptions', 'image_draw_core_content_exceptions', 'image_load_core_content_exceptions') then observation_value end) as image_any_core_exceptions,
        sum(case when observation_name in ('image_draw_appstart_exceptions', 'image_draw_exceptions', 'image_load_exceptions') then observation_value end) as image_any_exceptions,
        sum(case when observation_name = 'image_draw_appstart_exceptions' then observation_value end) as image_draw_appstart_exceptions,
        sum(case when observation_name = 'image_draw_exceptions' then observation_value end) as image_draw_exceptions,
        sum(case when observation_name = 'image_load_exceptions' then observation_value end) as image_load_exceptions
    from image t
    group by cookie_id, participant_id
) _
;
