select
    aw.cookie_id,
    aw.transaction_uid,
    aw.amount,
    aw.event_time,
    aw.item_id,
    aw.campaign_id,
    aw.x,
    aw.reason,
    aw.event_date,
    cm.vertical_id,
    cm.logical_category_id,
    cm.category_id,
    cm.subcategory_id,
    cl.region_internal_id as region_id
from
    dma.auction_withdrawal_refund aw
left join
    dma.current_microcategories cm
on
    aw.microcat_id = cm.microcat_id
    and is_active_microcat
left join 
    dma.current_locations cl
on
    aw.location_id = cl.location_id
where
    cast(event_date as date) between :first_date and :last_date
    -- and event_month between date_trunc('month' , :first_date) and date_trunc('month' , :last_date) -- @trino