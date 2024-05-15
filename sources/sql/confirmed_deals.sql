with
filtered_data as (
    select *
    from (
        select event_date, item_id, deal_type, deals_number, row_number() over(partition by item_id, deals_number order by event_date, deal_type) as rnb
        from (
            select cast(event_date as date) as event_date, cd.item_id, deal_type, row_number() over(partition by cd.item_id, deal_type order by cast(event_date as date)) as deals_number
            from dma.controlled_deals cd
            where deal_type not in ('buyer_rejected_deal', 'delivered_item')
    --             and cast(event_date as date) between :first_date and :last_date
                --and event_year is not null -- @trino
            union all
            select
                cast(co.accept_date as date) as event_date,
                coi.item_id,
                'delivered_item' as deal_type,
                row_number() over(partition by coi.item_id order by cast(create_date as date)) as deals_number
            from dma.current_order_item coi
            join dma.current_order co on co.deliveryorder_id = coi.deliveryorder_id
            where true
                and co.accept_date is not null
                and coi.seller_id not in (select User_id from dma."current_user" where IsTest)
    --             and cast(co.accept_date as date) between :first_date and :last_date
        ) t
    ) t
    where event_date between :first_date and :last_date
        and rnb = 1
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
    coalesce(usm.user_segment, ls.segment) as user_segment_market,
    coalesce(acd.is_asd, False) as is_asd
from filtered_data                fd
join /*+distrib(a,l)*/ dma.current_item ci on ci.item_id = fd.item_id -- для получения микроката
join dma.current_microcategories  cmc on cmc.microcat_id = ci.microcat_id

left join DMA.user_segment_market usm
    on ci.user_id = usm.user_id
    and cmc.logical_category_id = usm.logical_category_id
    and fd.event_date = usm.event_date
    and usm.reason_code is not null
    and usm.event_date between :first_date and :last_date
    -- and usm.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino

left join dict.segmentation_ranks ls on ls.logical_category_id = cmc.logical_category_id and ls.is_default

left join (
    select
        user_id,
        active_from_date,
        active_to_date,
        (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
        user_group_id
    from DMA.am_client_day_versioned
    where cast(active_from_date as date) <= :last_date
        and cast(active_to_date as date) >= :first_date
) acd on ci.user_id = acd.user_id and fd.event_date between acd.active_from_date and acd.active_to_date
