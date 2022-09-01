create fact image as
select
    t.observation_date::date as __date__,
    *
from dma.o_image_mobile t
;

create metrics image as
select
    sum(case when event_type = 'first_image' and image_draw_type = 'from_appstart' then duration end) as cnt_image_draw_appstart_duration,
    sum(case when event_type = 'first_image' and image_draw_type = 'from_appstart' then duration_events end) as cnt_image_draw_appstart_duration_events,
    sum(case when event_type = 'first_image' and image_draw_type = 'from_appstart' then events end) as cnt_image_draw_appstart_events,
    sum(case when event_type = 'first_image' and image_draw_type = 'from_appstart' then ifnull(events, 0) + ifnull(exceptions, 0) end) as cnt_image_draw_appstart_events_exceptions,
    sum(case when event_type = 'first_image' and image_draw_type = 'from_appstart' then events_p25 end) as cnt_image_draw_appstart_events_p25,
    sum(case when event_type = 'first_image' and image_draw_type = 'from_appstart' then events_p50 end) as cnt_image_draw_appstart_events_p50,
    sum(case when event_type = 'first_image' and image_draw_type = 'from_appstart' then events_p75 end) as cnt_image_draw_appstart_events_p75,
    sum(case when event_type = 'first_image' and image_draw_type = 'from_appstart' then events_p95 end) as cnt_image_draw_appstart_events_p95,
    sum(case when event_type = 'first_image' and image_draw_type = 'from_touch' then duration end) as cnt_image_draw_duration,
    sum(case when event_type = 'first_image' and image_draw_type = 'from_touch' then duration_events end) as cnt_image_draw_duration_events,
    sum(case when event_type = 'first_image' and image_draw_type = 'from_touch' then events end) as cnt_image_draw_events,
    sum(case when event_type = 'first_image' and image_draw_type = 'from_touch' then ifnull(events, 0) + ifnull(exceptions, 0) end) as cnt_image_draw_events_exceptions,
    sum(case when event_type = 'first_image' and image_draw_type = 'from_touch' then events_p25 end) as cnt_image_draw_events_p25,
    sum(case when event_type = 'first_image' and image_draw_type = 'from_touch' then events_p50 end) as cnt_image_draw_events_p50,
    sum(case when event_type = 'first_image' and image_draw_type = 'from_touch' then events_p75 end) as cnt_image_draw_events_p75,
    sum(case when event_type = 'first_image' and image_draw_type = 'from_touch' then events_p95 end) as cnt_image_draw_events_p95,
    sum(case when event_type = 'image' and image_draw_type is null then duration end) as cnt_image_load_duration,
    sum(case when event_type = 'image' and image_draw_type is null then duration_events end) as cnt_image_load_duration_events,
    sum(case when event_type = 'image' and image_draw_type is null then events end) as cnt_image_load_events,
    sum(case when event_type = 'image' and image_draw_type is null then ifnull(events, 0) + ifnull(exceptions, 0) end) as cnt_image_load_events_exceptions,
    sum(case when event_type = 'image' and image_draw_type is null then events_p25 end) as cnt_image_load_events_p25,
    sum(case when event_type = 'image' and image_draw_type is null then events_p50 end) as cnt_image_load_events_p50,
    sum(case when event_type = 'image' and image_draw_type is null then events_p75 end) as cnt_image_load_events_p75,
    sum(case when event_type = 'image' and image_draw_type is null then events_p95 end) as cnt_image_load_events_p95,
    sum(core_content_exceptions) as image_any_core_exceptions,
    sum(exceptions) as image_any_exceptions,
    sum(case when event_type = 'first_image' and image_draw_type = 'from_appstart' then core_content_exceptions end) as image_draw_appstart_core_exceptions,
    sum(case when event_type = 'first_image' and image_draw_type = 'from_appstart' then exceptions end) as image_draw_appstart_exceptions,
    sum(case when event_type = 'first_image' and image_draw_type = 'from_touch' then core_content_exceptions end) as image_draw_core_exceptions,
    sum(case when event_type = 'first_image' and image_draw_type = 'from_touch' then exceptions end) as image_draw_exceptions,
    sum(case when event_type = 'image' and image_draw_type is null then core_content_exceptions end) as image_load_core_exceptions,
    sum(case when event_type = 'image' and image_draw_type is null then exceptions end) as image_load_exceptions
from image t
;

create metrics image_cookie_id as
select
    sum(case when image_any_core_exceptions > 0 then 1 end) as user_image_core_exceptions,
    sum(case when image_draw_appstart_exceptions > 0 then 1 end) as user_image_draw_appstart_exceptions,
    sum(case when image_draw_exceptions > 0 then 1 end) as user_image_draw_exceptions,
    sum(case when image_any_exceptions > 0 then 1 end) as user_image_exceptions,
    sum(case when image_load_exceptions > 0 then 1 end) as user_image_load_exceptions
from (
    select
        cookie_id,
        sum(core_content_exceptions) as image_any_core_exceptions,
        sum(exceptions) as image_any_exceptions,
        sum(case when event_type = 'first_image' and image_draw_type = 'from_appstart' then exceptions end) as image_draw_appstart_exceptions,
        sum(case when event_type = 'first_image' and image_draw_type = 'from_touch' then exceptions end) as image_draw_exceptions,
        sum(case when event_type = 'image' and image_draw_type is null then exceptions end) as image_load_exceptions
    from image t
    group by cookie_id
) _
;
