create fact geo_coordinates_stream as
select
    t.accuracy,
    t.cookie_id as cookie,
    t.cookie_id,
    t.eid,
    t.error,
    t.event_date,
    t.freshness_hours,
    t.latitude,
    t.longitude,
    t.resolved
from dma.vo_coordinates_stream t
;

create metrics geo_coordinates_stream as
select
    sum(case when latitude is not null and longitude is not null and accuracy <= 1000 then 1 end) as any_coords_events_1000m,
    sum(case when latitude is not null and longitude is not null and accuracy <= 1000 and freshness_hours <= 8 then 1 end) as any_coords_events_1000m_8h,
    sum(case when latitude is not null and longitude is not null and accuracy <= 100 then 1 end) as any_coords_events_100m,
    sum(case when latitude is not null and longitude is not null and accuracy <= 100 and freshness_hours <= 1 then 1 end) as any_coords_events_100m_1h,
    sum(case when latitude is not null and longitude is not null and freshness_hours <= 1 then 1 end) as any_coords_events_1h,
    sum(case when latitude is not null and longitude is not null and accuracy <= 2000 then 1 end) as any_coords_events_2000m,
    sum(case when latitude is not null and longitude is not null and accuracy <= 2000 and freshness_hours <= 24 then 1 end) as any_coords_events_2000m_24h,
    sum(case when latitude is not null and longitude is not null and freshness_hours <= 24 then 1 end) as any_coords_events_24h,
    sum(case when latitude is not null and longitude is not null and freshness_hours <= 8 then 1 end) as any_coords_events_8h,
    sum(case when latitude is not null and longitude is not null then 1 end) as any_coords_events_with_coords,
    sum(case when eid = 4615 and resolved = True then 1 end) as coord_answers,
    sum(case when eid = 4615 and resolved = True and latitude is not null and longitude is not null and accuracy <= 1000 then 1 end) as coord_answers_1000m,
    sum(case when eid = 4615 and resolved = True and latitude is not null and longitude is not null and accuracy <= 1000 and freshness_hours <= 8 then 1 end) as coord_answers_1000m_8h,
    sum(case when eid = 4615 and resolved = True and latitude is not null and longitude is not null and accuracy <= 100 then 1 end) as coord_answers_100m,
    sum(case when eid = 4615 and resolved = True and latitude is not null and longitude is not null and accuracy <= 100 and freshness_hours <= 1 then 1 end) as coord_answers_100m_1h,
    sum(case when eid = 4615 and resolved = True and latitude is not null and longitude is not null and freshness_hours <= 1 then 1 end) as coord_answers_1h,
    sum(case when eid = 4615 and resolved = True and latitude is not null and longitude is not null and accuracy <= 2000 then 1 end) as coord_answers_2000m,
    sum(case when eid = 4615 and resolved = True and latitude is not null and longitude is not null and accuracy <= 2000 and freshness_hours <= 24 then 1 end) as coord_answers_2000m_24h,
    sum(case when eid = 4615 and resolved = True and latitude is not null and longitude is not null and freshness_hours <= 24 then 1 end) as coord_answers_24h,
    sum(case when eid = 4615 and resolved = True and latitude is not null and longitude is not null and freshness_hours <= 8 then 1 end) as coord_answers_8h,
    sum(case when eid = 4615 and resolved = True and latitude is not null and longitude is not null then 1 end) as coord_answers_with_coords,
    sum(case when eid = 4615 and error is not null then 1 end) as coord_answers_with_errors,
    sum(case when eid = 4615 then 1 end) as coord_request,
    sum(case when eid = 3508 then 1 end) as old_coord_events,
    sum(case when eid = 3508 and latitude is not null and longitude is not null and accuracy <= 1000 then 1 end) as old_coord_events_1000m,
    sum(case when eid = 3508 and latitude is not null and longitude is not null and accuracy <= 1000 and freshness_hours <= 8 then 1 end) as old_coord_events_1000m_8h,
    sum(case when eid = 3508 and latitude is not null and longitude is not null and accuracy <= 100 then 1 end) as old_coord_events_100m,
    sum(case when eid = 3508 and latitude is not null and longitude is not null and accuracy <= 100 and freshness_hours <= 1 then 1 end) as old_coord_events_100m_1h,
    sum(case when eid = 3508 and latitude is not null and longitude is not null and freshness_hours <= 1 then 1 end) as old_coord_events_1h,
    sum(case when eid = 3508 and latitude is not null and longitude is not null and accuracy <= 2000 then 1 end) as old_coord_events_2000m,
    sum(case when eid = 3508 and latitude is not null and longitude is not null and accuracy <= 2000 and freshness_hours <= 24 then 1 end) as old_coord_events_2000m_24h,
    sum(case when eid = 3508 and latitude is not null and longitude is not null and freshness_hours <= 24 then 1 end) as old_coord_events_24h,
    sum(case when eid = 3508 and latitude is not null and longitude is not null and freshness_hours <= 8 then 1 end) as old_coord_events_8h,
    sum(case when eid = 3508 and latitude is not null and longitude is not null then 1 end) as old_coord_events_with_coords
from geo_coordinates_stream t
;

create metrics geo_coordinates_stream_cookie as
select
    sum(case when any_coords_events_1000m > 0 then 1 end) as users_coords_1000m,
    sum(case when any_coords_events_1000m_8h > 0 then 1 end) as users_coords_1000m_8h,
    sum(case when any_coords_events_100m > 0 then 1 end) as users_coords_100m,
    sum(case when any_coords_events_100m_1h > 0 then 1 end) as users_coords_100m_1h,
    sum(case when any_coords_events_1h > 0 then 1 end) as users_coords_1h,
    sum(case when any_coords_events_2000m > 0 then 1 end) as users_coords_2000m,
    sum(case when any_coords_events_2000m_24h > 0 then 1 end) as users_coords_2000m_24h,
    sum(case when any_coords_events_24h > 0 then 1 end) as users_coords_24h,
    sum(case when any_coords_events_8h > 0 then 1 end) as users_coords_8h,
    sum(case when any_coords_events_with_coords > 0 then 1 end) as users_with_coords
from (
    select
        cookie_id, cookie,
        sum(case when latitude is not null and longitude is not null and accuracy <= 1000 then 1 end) as any_coords_events_1000m,
        sum(case when latitude is not null and longitude is not null and accuracy <= 1000 and freshness_hours <= 8 then 1 end) as any_coords_events_1000m_8h,
        sum(case when latitude is not null and longitude is not null and accuracy <= 100 then 1 end) as any_coords_events_100m,
        sum(case when latitude is not null and longitude is not null and accuracy <= 100 and freshness_hours <= 1 then 1 end) as any_coords_events_100m_1h,
        sum(case when latitude is not null and longitude is not null and freshness_hours <= 1 then 1 end) as any_coords_events_1h,
        sum(case when latitude is not null and longitude is not null and accuracy <= 2000 then 1 end) as any_coords_events_2000m,
        sum(case when latitude is not null and longitude is not null and accuracy <= 2000 and freshness_hours <= 24 then 1 end) as any_coords_events_2000m_24h,
        sum(case when latitude is not null and longitude is not null and freshness_hours <= 24 then 1 end) as any_coords_events_24h,
        sum(case when latitude is not null and longitude is not null and freshness_hours <= 8 then 1 end) as any_coords_events_8h,
        sum(case when latitude is not null and longitude is not null then 1 end) as any_coords_events_with_coords
    from geo_coordinates_stream t
    group by cookie_id, cookie
) _
;
