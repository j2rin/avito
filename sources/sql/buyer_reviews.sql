with seller_has_review as (
    select from_user_id, min(create_date) as first_date_review
    from dma.current_buyer_reviews
    group by 1
    )
select
    cast(cbr.create_date as date) as event_date,
    rpc.cookie_id,
    cbr.from_user_id as user_id,
    cbr.to_user_id as buyer_id,
    rpc.platform_id,
    reviewstatus,
    cbr.score,
    coalesce(rpc.review_add_trigger, 'null')                    as review_add_trigger,
    coalesce(rpc.page_from, 'null')                             as review_page_from,
    coalesce(buyer_review_form_type, 'null')                    as buyer_review_form_type,
    coalesce(order_status, 'null')                              as order_status,
    cbr.buyer_review_id,
     -- Dimensions -----------------------------------------------------------------------------------------------------
     -- microcat_dimensions
    cm.vertical_id,
    cm.logical_category_id,
    cm.category_id,
    cm.subcategory_id,
    cm.Param1_microcat_id                                        as param1_id,
    cm.Param2_microcat_id                                        as param2_id,
    cm.Param3_microcat_id                                        as param3_id,
    cm.Param4_microcat_id                                        as param4_id,
    -- location_dimensions
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end                                as region_id,
    case cl.level when 3 then cl.Location_id end                                                          as city_id,
    cl.LocationGroup_id                                                                                   as location_group_id,
    cl.City_Population_Group                                                                              as population_group,
    cl.Logical_Level                                                                                      as location_level_id,
    coalesce(usm.user_segment, sr.segment)                                                                as user_segment_market,
    coalesce(cast(first_date_review as date) < cast(cbr.create_date as date), false)                      as has_review
from dma.current_buyer_reviews as cbr
    left join /*+jtype(fm)*/ dma.review_buyer_params_clickstream  as rpc on cbr.buyer_review_external_id = rpc.buyer_review_id
    left join /*+jtype(h)*/  dma.current_microcategories    as cm  on cbr.microcat_id = cm.microcat_id
    left join /*+jtype(h)*/  dma.current_locations          as cl  on cbr.Location_id = cl.location_id
    left join dma.user_segment_market usm on cbr.from_user_id = usm.user_id
                                        and cm.logical_category_id = usm.logical_category_id
                                        and cast(cbr.create_date as date) = usm.event_date
                                        and usm.reason_code is not null
                                        and usm.event_date between :first_date and :last_date
                                        -- and usm.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
    left join dict.segmentation_ranks sr on sr.logical_category_id = cm.logical_category_id and is_default
    left join seller_has_review r on cbr.from_user_id = r.from_user_id
where cast(cbr.create_date as date) between :first_date and :last_date
-- and create_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino