with
am_client_day as (
    select
        user_id,
        active_from_date,
        active_to_date,
        (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
        user_group_id
    from DMA.am_client_day_versioned
    where active_from_date::date <= :last_date
        and active_to_date::date >= :first_date
),
count_all_data as (
    select event_date::date as event_date, cd.item_id, deal_type, row_number() over(partition by cd.item_id, deal_type order by event_date::date) as deals_number
    from dma.controlled_deals cd
    where deal_type not in ('buyer_rejected_deal', 'delivered_item')
        and event_date::date between :first_date and :last_date
    union all
    select
        co.accept_date::date as event_date,
        coi.item_id,
        'delivered_item' as deal_type,
        row_number() over(partition by coi.item_id order by create_date::date) as deals_number
    from dma.current_order_item coi
    join dma.current_order co
        using (deliveryorder_id)
    where true
        -- and 'delivered_item' in ({{deal_type}})
        and co.accept_date is not null
        and coi.seller_id not in (select User_id from dma.current_user where IsTest)
        and co.accept_date::date between :first_date and :last_date
),
filtered_data as (
    select event_date, item_id, deal_type, deals_number, row_number() over(partition by item_id, deals_number order by event_date, deal_type) as rnb
    from count_all_data
)
select
    fd.event_date,
    fd.item_id,
    ci.user_id,
    fd.deal_type,
    fd.deals_number,
    cmc.logical_category_id,
    cmc.vertical_id,
    cmc.category_id,
    cmc.subcategory_id,
    nvl(usm.user_segment, ls.segment) as user_segment_market,
    nvl(acd.is_asd, False) as is_asd
from filtered_data                fd
join dma.current_item             ci using(item_id) -- для получения микроката
join dma.current_microcategories  cmc using(microcat_id)
left join dma.user_segment_market usm on ci.user_id = usm.user_id and cmc.logical_category_id = usm.logical_category_id
                                                                    and fd.event_date interpolate previous value usm.converting_date
left join dict.segmentation_ranks ls on ls.logical_category_id = cmc.logical_category_id and ls.is_default
left join am_client_day           acd on ci.user_id = acd.user_id and fd.event_date between acd.active_from_date and acd.active_to_date
where rnb = 1