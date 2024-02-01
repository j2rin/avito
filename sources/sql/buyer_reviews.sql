select *
from (
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
        lag(cbr.buyer_review_id) over (partition by from_user_id order by cbr.create_date) is not null        as has_review
    from dma.current_buyer_reviews as cbr
        left join /*+jtype(fm)*/ dma.review_buyer_params_clickstream  as rpc on cbr.buyer_review_external_id = rpc.buyer_review_id
        left join /*+jtype(h)*/  dma.current_microcategories    as cm  on cbr.microcat_id = cm.microcat_id
        left join /*+jtype(h)*/  dma.current_locations          as cl  on cbr.Location_id = cl.location_id
        left join dma.user_segment_market usm on cbr.from_user_id = usm.user_id
                                            and cast(cbr.create_date as date) between converting_date and max_valid_date
                                            and cm.logical_category_id = usm.logical_category_id
        left join dict.segmentation_ranks sr on sr.logical_category_id = cm.logical_category_id and is_default
    ) data
where cast(event_date as date) between :first_date and :last_date
--and create_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino