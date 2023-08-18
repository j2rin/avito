with /*+ENABLE_WITH_CLAUSE_MATERIALIZATION */
daily_active_listers as (
    select
        sia.event_date,
        sia.user_id,
        cm.logical_category_id,
        cm.vertical_id,
        count(sia.item_id) as items
    from DMA.o_seller_item_active sia
    join dma.current_microcategories cm on cm.microcat_id = sia.microcat_id
    where event_date::date between :first_date::date and :last_date::date
        and is_active
        and not coalesce(is_marketplace, false)
        and sia.event_date::date between :first_date::date and :last_date::date
        and user_id is not null
    group by 1, 2, 3, 4
),
daily_active_listers_w_segment as (
    select
        dal.event_date,
        dal.user_id,
        dal.logical_category_id,
        dal.vertical_id,
        dal.items,
        coalesce(usm.user_segment, ls.segment) as user_segment_market,
        coalesce(usm.user_segment is null and ls.segment is not null, False) as is_default_segment
    from daily_active_listers dal
    left join dma.user_segment_market usm
        on usm.user_id = dal.user_id
        and usm.logical_category_id = dal.logical_category_id
        and dal.event_date interpolate previous value usm.converting_date
    left join dict.segmentation_ranks ls
        on ls.logical_category_id = dal.logical_category_id
        and ls.is_default
        and ls.logical_category != 'Any'
)
select /*+syntactic_join*/
    t.event_date,
    t.user_id,
    t.logical_category_id,
    t.vertical_id,
    t.items,
    t.user_segment_market,
    t.is_default_segment,
    t.user_segment_rank,
    pur.transaction_amount_net_adj is not null as is_paying_seller,
    row_number() over (partition by t.user_id, t.event_date order by t.user_segment_rank, t.is_default_segment, t.items desc) = 1 as is_seller_total
from (
    select
        event_date,
        user_id,
        logical_category_id,
        vertical_id,
        items,
        user_segment_market,
        is_default_segment,
        case
            when split_part(user_segment_market, '.', 1) = 'Enterprise' then 1
            when split_part(user_segment_market, '.', 1) = 'MidMarket' then 2
            when split_part(user_segment_market, '.', 1) = 'Private (Earning)' then 3
            else 4
        end as user_segment_rank,
        row_number() over (partition by user_id, event_date, vertical_id order by user_segment_rank, is_default_segment, items desc) as rnk
    from daily_active_listers_w_segment dal
) t
left join (
    select
        pur.event_date,
        pur.user_id,
        cm.vertical_id,
        sum(pur.transaction_amount_net_adj) as transaction_amount_net_adj
    from dma.paying_user_report pur
    join dma.current_transaction_type ctt using(TransactionType_id)
    join dma.current_microcategories cm on pur.microcat_id = cm.microcat_id and cm.microcat_id != -1
    where ctt.IsRevenue
        and pur.event_date::date between :first_date::date and :last_date::date
    group by 1, 2, 3
) pur on pur.user_id=t.user_id and pur.event_date=t.event_date and pur.vertical_id=t.vertical_id
where rnk = 1
