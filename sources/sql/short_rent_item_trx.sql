with 
am_client_day as 
(
    select user_id,
           active_from_date,
           active_to_date,
           (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
           user_group_id
    from DMA.am_client_day_versioned
),
item_data as
(
    select 
        ia.event_date,
        ia.user_id,
        ia.item_id,
        ia.platform_id,
        ia.location_id,
        cmc.vertical_id,
        cmc.logical_category_id,
        cmc.category_id,
        cmc.subcategory_id,
        isr.ShortTermRent,
        row_number() over(partition by ia.item_id, ia.event_date order by isr.actual_date desc) as rnb
    from dma.o_seller_item_active ia
    join dds.s_item_shorttermrent isr on isr.item_id = ia.item_id and ia.event_date >= isr.actual_date::date
    join dma.current_microcategories cmc using(microcat_id)
    where cmc.logical_category_id = 1393250002 -- Realty.ShortRent
)
select 
    t.event_date,
    t.user_id,
    t.item_id,
    t.platform_id,
    t.vertical_id,
    t.logical_category_id,
    t.category_id,
    t.subcategory_id,
    ----
    decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id) as region_id,
    case when nvl(acd.is_asd, False) then 1 else 0 end as is_asd,
    nvl(usm.user_segment, ls.segment) as user_segment_market
from item_data as t
left join am_client_day as acd on acd.user_id = t.user_id and t.event_date between acd.active_from_date and acd.active_to_date
left join dma.user_segment_market usm on t.user_id = usm.user_id and t.logical_category_id = usm.logical_category_id
                                                                 and t.event_date interpolate previous value usm.converting_date
left join dict.segmentation_ranks ls on ls.logical_category_id = t.logical_category_id and ls.is_default
left join dma.current_locations cl on cl.Location_id = t.location_id
where rnb = 1 and ShortTermRent
and event_date::date between :first_date and :last_date