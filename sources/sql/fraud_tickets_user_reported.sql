select  
        create_date,
        coalesce(item_user_id, FraudUser_id) as user_id,
        vertical_id,
        logical_category_id,
        category_id,
        subcategory_id
from DMA.fraud_support_tickets as fst
        left join dma.current_microcategories cm on fst.item_microcat_id = cm.microcat_id
where TicketFraudInfo_id is not null and coalesce(item_user_id, FraudUser_id) is not null
    and cast(create_date as date) between :first_date and :last_date
    --and create_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
