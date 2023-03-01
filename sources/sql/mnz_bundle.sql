select
    t.event_date,
    t.user_id,
    t.item_id,
    t.activation_date,
    t.close_date,
    t.microcat_id,
    cm.logical_category_id,
    cm.vertical_id,
    cm.category_id,
    cm.subcategory_id,
    cm.Param1_microcat_id as param1_id,
	cm.Param2_microcat_id as param2_id,
	t.platform_id,
	nvl(acd.is_asd, False) as is_asd,
    acd.user_group_id      as asd_user_group_id,
	tu.user_id is not null as is_tariff_user,
	nvl(usm.user_segment, ls.segment) as user_segment_market,
    t.transaction_type,
    t.amount_net_adj,
    t.exposure,
    t.exposure_eventtype,
    t.first_day_transaction_count
from (
    select
        mbt.event_date,
        mbt.user_id,
        mbt.item_id,
        mbt.activation_date,
        mbt.close_date,
        mbt.microcat_id,
        mbt.platform_id,
        ctt.transaction_type,
        case when transaction_type in ('bundle return', 'VAS return', 'Performance VAS return', 'Bundle VAS return') then -mbt.amount_net_adj else mbt.amount_net_adj end as amount_net_adj,
        cast(null as numeric) as exposure,
        cast(null as varchar) as exposure_eventtype,
        cast(null as numeric) as first_day_transaction_count
    from dma.mnz_bundle_transactions mbt
    left join dma.current_transaction_type ctt using(TransactionType_id)
    where mbt.event_date::date between :first_date and :last_date

    union all

    select
        mbe.event_date,
        mbe.user_id,
        cast(null as numeric) as item_id,
        cast(null as date) as activation_date,
        cast(null as date) as close_date,
        mbe.microcat_id,
        mbe.platform_id,
        cast(null as varchar) as transaction_type,
        cast(null as numeric) as amount_net_adj,
        mbe.exposure,
        mbe.exposure_eventtype,
        mbe.first_day_transaction_count
    from dma.mnz_bundle_exposure mbe
    where mbe.event_date::date between :first_date and :last_date
) t
left join dma.current_microcategories cm using(microcat_id)

left join dict.segmentation_ranks ls
    on ls.logical_category_id = cm.logical_category_id
    and ls.is_default

left join (
    select
        usm.user_id,
        usm.logical_category_id,
        usm.user_segment,
        usm.from_date,
        usm.to_date
    from (
        select
            user_id,
            logical_category_id,
            user_segment,
            converting_date as from_date,
            lead(converting_date, 1, '20990101') over(partition by user_id, logical_category_id order by converting_date) as to_date
        from DMA.user_segment_market
        where true
            and user_id in (
                select distinct user_id
                from dma.mnz_bundle_transactions
                where event_date::date between :first_date and :last_date
            )
            and converting_date <= :last_date::date
    ) usm
    where usm.to_date >= :first_date::date
) usm
    on  t.user_id = usm.user_id
    and t.event_date::date >= usm.from_date and t.event_date::date < usm.to_date
    and cm.logical_category_id = usm.logical_category_id

left join (
    select
        user_id,
        active_from_date,
        active_to_date,
        (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
        user_group_id
    from DMA.am_client_day_versioned
    where active_from_date <= :last_date
        and active_to_date >= :first_date
) acd
    on t.user_id = acd.user_id
    and t.event_date between acd.active_from_date and acd.active_to_date

left join (
    select
        user_id,
        event_date,
        logical_category_id
    from dma.presence_users_distribution
    where product_type in ('subscription 1.0', 'tariff', 'package')
        and event_date::date between :first_date and :last_date
    group by 1,2,3
) tu
    on tu.user_id = t.user_id
    and cm.logical_category_id = tu.logical_category_id
    and tu.event_date = t.event_date
