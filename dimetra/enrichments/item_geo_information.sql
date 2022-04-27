create enrichment geo_information as
select
    ig.CoordinatesIsManual as CoordinatesIsManual,
    ig.metro_id as metro_id,
    ig.address_length as address_length,
    ig.has_address as has_address,
    ig.has_metro as has_metro,
    ig.has_street as has_street,
    ig.has_building as has_building,
    ig.no_city as no_city,
    ig.wrong_order as wrong_order,
    ig.location_distance as location_distance,
    ig.metro_distance as metro_distance,
    ig.has_address_id as has_address_id,
    ig.CoordinatesLatitude as CoordinatesLatitude,
    ig.CoordinatesLongitude as CoordinatesLongitude,
    ig.address_id as address_id,
    ig.min_kind_level as min_kind_level
from :fact_table t
left join dma.item_geo_information ig   on  ig.user_id = t.user_id
                                        and ig.event_date = t.event_date
                                        and ig.item_id = t.item_id
;
