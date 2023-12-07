with ratings_services as 
(
select 
    urs.*,
    coalesce(lead(date_from) over (partition by user_id order by date_from), cast('2100-01-01' as date)) as date_to
from dma.user_ratings_services urs
--where date_year between date_trunc('year', :first_date) AND date_trunc('year', :last_date) --@trino
)
select 
    ss.event_date,
    ss.user_id,
    ss.item_id,
    coalesce(rs.active_reviews_count,0)                              as active_reviews_count_services,
    coalesce(rs.rating_reviews_count,0)                              as rating_reviews_count_services,
    ratingfloat,
    contacts,
    -- Dimensions -----------------------------------------------------------------------------------------------------
    cm.vertical_id                                               as vertical_id,
    cm.logical_category_id                                       as logical_category_id,
    cm.category_id                                               as category_id,
    cm.subcategory_id                                            as subcategory_id,
    cm.Param1_microcat_id                                        as param1_id,
    cm.Param2_microcat_id                                        as param2_id,
    cm.Param3_microcat_id                                        as param3_id,
    cm.Param4_microcat_id                                        as param4_id,
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
    cl.LocationGroup_id                                          as location_group_id,
    cl.City_Population_Group                                     as population_group,
    cl.Logical_Level                                             as location_level_id
from DMA.o_seller_item_active ss
left join dma.current_item ci on ci.item_id = ss.item_id
left join dma.current_microcategories cm on cm.microcat_id = ss.microcat_id
left join dma.current_locations cl on cl.location_id = ci.location_id
left join ratings_services rs on rs.user_id = ss.user_id and ss.event_date >= rs.date_from and ss.event_date < date_to
where event_date between :first_date and :last_date
