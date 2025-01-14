 select
    pmd.user_id,
    pmd.event_date,
    pmd.vertical_id,
    pmd.is_pro,
    pmd.logical_category_id,
    pmd.transaction_amount,
    target_contacts,
    case 
        when target_contacts > 0 
        then 1
        else 0 
    end as seller_with_at_least_one_contact
from DMA.avito_pro_metrics_daily pmd
where cast(event_date as date) between :first_date and :last_date
    -- and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
