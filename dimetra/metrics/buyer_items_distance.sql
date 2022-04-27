create fact buyer_items_distance as
select
    t.city_id,
    t.cookie_id as cookie,
    t.cookie_id,
    t.distance,
    t.event_date,
    t.item_city_id,
    t.item_location_group_id,
    t.location_group_id
from dma.vo_buyers_items_distance t
;

create metrics buyer_items_distance as
select
    sum(distance) as buyer_item_distance,
    sum(case when distance <= 1000 then 1 end) as buyer_item_distance_1000km,
    sum(case when distance <= 100 then 1 end) as buyer_item_distance_100km,
    sum(case when distance <= 10 then 1 end) as buyer_item_distance_10km,
    sum(case when distance <= 1 then 1 end) as buyer_item_distance_1km,
    sum(case when distance <= 25 then 1 end) as buyer_item_distance_25km,
    sum(case when distance <= 3 then 1 end) as buyer_item_distance_3km,
    sum(case when distance <= 500 then 1 end) as buyer_item_distance_500km,
    sum(case when distance <= 50 then 1 end) as buyer_item_distance_50km,
    sum(case when distance <= 5 then 1 end) as buyer_item_distance_5km,
    sum(case when item_city_id = city_id then 1 end) as buyer_item_same_city,
    sum(case when item_location_group_id = location_group_id then 1 end) as buyer_item_same_fo,
    sum(case when item_city_id = city_id then 1 end) as buyer_item_same_region
from buyer_items_distance t
;

create metrics buyer_items_distance_cookie as
select
    sum(case when buyer_item_distance_1000km > 0 then 1 end) as user_buyer_item_distance_1000km,
    sum(case when buyer_item_distance_100km > 0 then 1 end) as user_buyer_item_distance_100km,
    sum(case when buyer_item_distance_10km > 0 then 1 end) as user_buyer_item_distance_10km,
    sum(case when buyer_item_distance_1km > 0 then 1 end) as user_buyer_item_distance_1km,
    sum(case when buyer_item_distance_25km > 0 then 1 end) as user_buyer_item_distance_25km,
    sum(case when buyer_item_distance_3km > 0 then 1 end) as user_buyer_item_distance_3km,
    sum(case when buyer_item_distance_500km > 0 then 1 end) as user_buyer_item_distance_500km,
    sum(case when buyer_item_distance_50km > 0 then 1 end) as user_buyer_item_distance_50km,
    sum(case when buyer_item_distance_5km > 0 then 1 end) as user_buyer_item_distance_5km,
    sum(case when buyer_item_same_city > 0 then 1 end) as user_buyer_item_same_city,
    sum(case when buyer_item_same_fo > 0 then 1 end) as user_buyer_item_same_fo,
    sum(case when buyer_item_same_region > 0 then 1 end) as user_buyer_item_same_region
from (
    select
        cookie_id, cookie,
        sum(case when distance <= 1000 then 1 end) as buyer_item_distance_1000km,
        sum(case when distance <= 100 then 1 end) as buyer_item_distance_100km,
        sum(case when distance <= 10 then 1 end) as buyer_item_distance_10km,
        sum(case when distance <= 1 then 1 end) as buyer_item_distance_1km,
        sum(case when distance <= 25 then 1 end) as buyer_item_distance_25km,
        sum(case when distance <= 3 then 1 end) as buyer_item_distance_3km,
        sum(case when distance <= 500 then 1 end) as buyer_item_distance_500km,
        sum(case when distance <= 50 then 1 end) as buyer_item_distance_50km,
        sum(case when distance <= 5 then 1 end) as buyer_item_distance_5km,
        sum(case when item_city_id = city_id then 1 end) as buyer_item_same_city,
        sum(case when item_location_group_id = location_group_id then 1 end) as buyer_item_same_fo,
        sum(case when item_city_id = city_id then 1 end) as buyer_item_same_region
    from buyer_items_distance t
    group by cookie_id, cookie
) _
;
