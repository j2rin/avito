select 
    buyer_cookie_id as cookie_id,
    x_eid,
    cast(action_time as date) as event_date,
    -- Dimensions -----------------------------------------------------------------------------------------------------
    call_source_detailed, ---Очень желательно, чтобы у дименшена был айдишник, а не только varchar-представление.
    -------------------------------------------------------------------------------------------------------------------
    cast(coalesce(sum(amount_net) / 1.2, 0) as int) as cpa_call_revenue_net_adj
from dma.re_nd_cpa_call_source_detailed
where cast(action_time as date) between :first_date and :last_date
group by 1, 2, 3, 4
