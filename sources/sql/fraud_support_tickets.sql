select
    create_date,
    is_fraud,
    ticket_author_role,
    where_is_avito_messenger,
    where_is_whatsapp,
    where_is_another_messenger,
    where_is_mail,
    where_is_other,
    where_is_phone,
    FraudUsers_count,
    ticket_user_id as user_id,
    cookie_id, 
    is_delivery_user,
    vertical_id,
    logical_category_id,
    category_id,
    subcategory_id
from dma.fraud_support_tickets fst
left join dma.current_microcategories cm on fst.item_microcat_id = cm.microcat_id
where TicketFraudInfo_id is not null
and cast(create_date as date) between :first_date and :last_date
