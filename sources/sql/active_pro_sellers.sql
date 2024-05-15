with /*+ENABLE_WITH_CLAUSE_MATERIALIZATION */
daily_active_listers as (
    select
        sia.event_date,
        sia.user_id,
        coalesce(lc.vertical_id, cm.vertical_id) as vertical_id,
        coalesce(lc.logical_category_id, cm.logical_category_id) as logical_category_id,
        count(sia.item_id) as items
    from DMA.o_seller_item_active sia
    left join /*+jtype(h),distrib(l,a)*/ (
        select infmquery_id, logcat_id
        from infomodel.current_infmquery_category
        where infmquery_id in (
            select distinct infmquery_id
            from dma.o_seller_item_active
            where cast(event_date as date) between :first_date and :last_date
                and infmquery_id is not null
        )
    ) ic on ic.infmquery_id = sia.infmquery_id
    left join dma.current_logical_categories lc on lc.logcat_id = ic.logcat_id
    left join /*+jtype(h),distrib(l,a)*/ dma.current_microcategories cm on cm.microcat_id = sia.microcat_id
    where cast(sia.event_date as date) between :first_date and :last_date
        and sia.is_active
        and not coalesce(sia.is_marketplace, false)
        and not coalesce(sia.is_user_test, false)
        and sia.user_id is not null
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
    left join /*+jtype(h),distrib(l,r)*/ DMA.user_segment_market usm
        on  dal.user_id = usm.user_id
        and dal.event_date = usm.event_date
        and dal.logical_category_id = usm.logical_category_id
        and usm.reason_code is not null
        and usm.event_date between :first_date and :last_date
        -- and usm.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
    left join dict.segmentation_ranks ls
        on ls.logical_category_id = dal.logical_category_id
        and ls.is_default
        and ls.logical_category_id != -1
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
        *,
        row_number() over (partition by user_id, event_date, vertical_id order by user_segment_rank, is_default_segment, items desc) as rnk
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
            end as user_segment_rank
        from daily_active_listers_w_segment dal
    ) t
) t
left join (
    select
        pur.event_date,
        pur.user_id,
        cm.vertical_id,
        sum(pur.transaction_amount_net_adj) as transaction_amount_net_adj
    from dma.paying_user_report pur
    join dma.current_transaction_type ctt on ctt.TransactionType_id = pur.TransactionType_id
    join dma.current_microcategories cm on pur.microcat_id = cm.microcat_id and cm.microcat_id != -1
    where ctt.IsRevenue
        and cast(pur.event_date as date) between :first_date and :last_date
        -- and pur.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
    group by 1, 2, 3
) pur on pur.user_id=t.user_id and pur.event_date=t.event_date and pur.vertical_id=t.vertical_id
where rnk = 1
