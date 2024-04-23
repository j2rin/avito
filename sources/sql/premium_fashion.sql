with b2c_items as (
select ci.user_id, item_id
from dds.L_User_PremiumShop ps
join dma.current_item ci on ci.user_id = ps.user_id
)
select pe.*,
       case when bi.item_id is not null then 1 else 0 end as is_b2c
from DMA.premium_events_tracker pe
left join b2c_items bi on bi.item_id = pe.item_id
where 1=1
    and cast(event_date as date) between :first_date and :last_date
    --and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
