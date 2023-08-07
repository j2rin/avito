select  
        create_date,
        case 
            when item_user_id is not null then item_user_id
            when FraudUser_id is not null then FraudUser_id
            end as user_id,
        vertical_id,
        logical_category_id,
        category_id,
        subcategory_id
from DMA.fraud_support_tickets as fst
        left join dma.current_microcategories cm on fst.item_microcat_id = cm.microcat_id
        where TicketFraudInfo_id is not null and user_id is not null
and create_date::date between :first_date and :last_date