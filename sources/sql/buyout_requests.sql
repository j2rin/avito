select
    cbr.buyout_request_id,
    cbr.bought_out_dttm                                                         as event_date,
    cbr.user_id,
    cbr.item_id,
    cbr.imei,
    cbr.brand,
    cbr.catalog_uid_ext,
    cbr.buyout_partner_id,
    cbr.subsidy_size,
    cbr.event_date                                                              as create_date,
    coalesce(cbr.boughtout_price,cbr.suggested_price)                                as boughtout_price,
    cast ((coalesce(cbr.boughtout_price,cbr.suggested_price) * 0.1) as int)          as boughtout_revenue,
    coalesce(cbr.boughtout_price,cbr.suggested_price) + coalesce(subsidy_size , 0)        as boughtout_price_subsidized,
    0                                                                           as platform_id, -- Undefined
--- Dimensions --------------------------------------------------------------------------------------------
    500005                                                                      as vertical_id, --Goods
    267188500001                                                                as logical_category_id, --Goods.Smartphones
--- Location ----------------------------------------------------------------------------------------------
    cl.location_id                                                              as location_id,
    case when cl.level = 3 then cl.ParentLocation_id else cl.Location_id end    as region_id,
    case when cl.level = 3 then cl.Location_id else null end                    as city_id,
    cl.LocationGroup_id                                                         as location_group_id,
    cl.City_Population_Group                                                    as population_group,
    cl.Logical_Level                                                            as location_level_id
from dma.current_buyout_requests cbr
left join dma.current_locations cl
    on coalesce(cbr.request_location_id,cbr.location_id)=cl.location_id
where 1=1
     and cast(cbr.bought_out_dttm as date) between :first_date and :last_date
