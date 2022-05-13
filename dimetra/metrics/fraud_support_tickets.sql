create fact fraud_support_tickets as
select
    t.create_date as __date__,
    t.cookie_id as cookie,
    t.cookie_id,
    t.create_date,
    t.is_fraud,
    t.ticket_author_role,
    t.where_is_avito_messenger
from dma.vo_fraud_support_tickets t
;

create metrics fraud_support_tickets as
select
    sum(1) as fraud_tickets,
    sum(case when where_is_avito_messenger = True then 1 end) as fraud_tickets_avito_messenger,
    sum(case when where_is_avito_messenger = True and ticket_author_role = 'buyer' then 1 end) as fraud_tickets_avito_messenger_buyer,
    sum(case when where_is_avito_messenger = True and ticket_author_role = 'seller' then 1 end) as fraud_tickets_avito_messenger_seller,
    sum(case when ticket_author_role = 'buyer' then 1 end) as fraud_tickets_buyer,
    sum(case when is_fraud = True then 1 end) as fraud_tickets_fraud_commited,
    sum(case when is_fraud = True and where_is_avito_messenger = True and ticket_author_role = 'buyer' then 1 end) as fraud_tickets_fraud_commited_avito_messenger_buyer,
    sum(case when is_fraud = True and where_is_avito_messenger = True and ticket_author_role = 'seller' then 1 end) as fraud_tickets_fraud_commited_avito_messenger_seller,
    sum(case when is_fraud = True and ticket_author_role = 'buyer' then 1 end) as fraud_tickets_fraud_commited_buyer,
    sum(case when is_fraud = True and where_is_avito_messenger = False and ticket_author_role = 'buyer' then 1 end) as fraud_tickets_fraud_commited_other_messenger_buyer,
    sum(case when is_fraud = True and where_is_avito_messenger = False and ticket_author_role = 'seller' then 1 end) as fraud_tickets_fraud_commited_other_messenger_seller,
    sum(case when is_fraud = True and ticket_author_role = 'seller' then 1 end) as fraud_tickets_fraud_commited_seller,
    sum(case when is_fraud = True and where_is_avito_messenger = True then 1 end) as fraud_tickets_fraud_committed_avito_messenger,
    sum(case when is_fraud = True and where_is_avito_messenger = False then 1 end) as fraud_tickets_fraud_committed_other_messenger,
    sum(case when where_is_avito_messenger = False then 1 end) as fraud_tickets_other_messenger,
    sum(case when where_is_avito_messenger = False and ticket_author_role = 'buyer' then 1 end) as fraud_tickets_other_messenger_buyer,
    sum(case when where_is_avito_messenger = False and ticket_author_role = 'seller' then 1 end) as fraud_tickets_other_messenger_seller,
    sum(case when ticket_author_role = 'seller' then 1 end) as fraud_tickets_seller
from fraud_support_tickets t
;

create metrics fraud_support_tickets_cookie as
select
    sum(case when fraud_tickets > 0 then 1 end) as unq_fraud_tickets,
    sum(case when fraud_tickets_avito_messenger > 0 then 1 end) as unq_fraud_tickets_avito_messenger,
    sum(case when fraud_tickets_avito_messenger_buyer > 0 then 1 end) as unq_fraud_tickets_avito_messenger_buyer,
    sum(case when fraud_tickets_avito_messenger_seller > 0 then 1 end) as unq_fraud_tickets_avito_messenger_seller,
    sum(case when fraud_tickets_buyer > 0 then 1 end) as unq_fraud_tickets_buyer,
    sum(case when fraud_tickets_fraud_commited > 0 then 1 end) as unq_fraud_tickets_fraud_commited,
    sum(case when fraud_tickets_fraud_commited_avito_messenger_buyer > 0 then 1 end) as unq_fraud_tickets_fraud_commited_avito_messenger_buyer,
    sum(case when fraud_tickets_fraud_commited_avito_messenger_seller > 0 then 1 end) as unq_fraud_tickets_fraud_commited_avito_messenger_seller,
    sum(case when fraud_tickets_fraud_commited_buyer > 0 then 1 end) as unq_fraud_tickets_fraud_commited_buyer,
    sum(case when fraud_tickets_fraud_commited_other_messenger_buyer > 0 then 1 end) as unq_fraud_tickets_fraud_commited_other_messenger_buyer,
    sum(case when fraud_tickets_fraud_commited_other_messenger_seller > 0 then 1 end) as unq_fraud_tickets_fraud_commited_other_messenger_seller,
    sum(case when fraud_tickets_fraud_commited_seller > 0 then 1 end) as unq_fraud_tickets_fraud_commited_seller,
    sum(case when fraud_tickets_fraud_committed_avito_messenger > 0 then 1 end) as unq_fraud_tickets_fraud_committed_avito_messenger,
    sum(case when fraud_tickets_fraud_committed_other_messenger > 0 then 1 end) as unq_fraud_tickets_fraud_committed_other_messenger,
    sum(case when fraud_tickets_other_messenger > 0 then 1 end) as unq_fraud_tickets_other_messenger,
    sum(case when fraud_tickets_other_messenger_buyer > 0 then 1 end) as unq_fraud_tickets_other_messenger_buyer,
    sum(case when fraud_tickets_other_messenger_seller > 0 then 1 end) as unq_fraud_tickets_other_messenger_seller,
    sum(case when fraud_tickets_seller > 0 then 1 end) as unq_fraud_tickets_seller
from (
    select
        cookie_id, cookie,
        sum(1) as fraud_tickets,
        sum(case when where_is_avito_messenger = True then 1 end) as fraud_tickets_avito_messenger,
        sum(case when where_is_avito_messenger = True and ticket_author_role = 'buyer' then 1 end) as fraud_tickets_avito_messenger_buyer,
        sum(case when where_is_avito_messenger = True and ticket_author_role = 'seller' then 1 end) as fraud_tickets_avito_messenger_seller,
        sum(case when ticket_author_role = 'buyer' then 1 end) as fraud_tickets_buyer,
        sum(case when is_fraud = True then 1 end) as fraud_tickets_fraud_commited,
        sum(case when is_fraud = True and where_is_avito_messenger = True and ticket_author_role = 'buyer' then 1 end) as fraud_tickets_fraud_commited_avito_messenger_buyer,
        sum(case when is_fraud = True and where_is_avito_messenger = True and ticket_author_role = 'seller' then 1 end) as fraud_tickets_fraud_commited_avito_messenger_seller,
        sum(case when is_fraud = True and ticket_author_role = 'buyer' then 1 end) as fraud_tickets_fraud_commited_buyer,
        sum(case when is_fraud = True and where_is_avito_messenger = False and ticket_author_role = 'buyer' then 1 end) as fraud_tickets_fraud_commited_other_messenger_buyer,
        sum(case when is_fraud = True and where_is_avito_messenger = False and ticket_author_role = 'seller' then 1 end) as fraud_tickets_fraud_commited_other_messenger_seller,
        sum(case when is_fraud = True and ticket_author_role = 'seller' then 1 end) as fraud_tickets_fraud_commited_seller,
        sum(case when is_fraud = True and where_is_avito_messenger = True then 1 end) as fraud_tickets_fraud_committed_avito_messenger,
        sum(case when is_fraud = True and where_is_avito_messenger = False then 1 end) as fraud_tickets_fraud_committed_other_messenger,
        sum(case when where_is_avito_messenger = False then 1 end) as fraud_tickets_other_messenger,
        sum(case when where_is_avito_messenger = False and ticket_author_role = 'buyer' then 1 end) as fraud_tickets_other_messenger_buyer,
        sum(case when where_is_avito_messenger = False and ticket_author_role = 'seller' then 1 end) as fraud_tickets_other_messenger_seller,
        sum(case when ticket_author_role = 'seller' then 1 end) as fraud_tickets_seller
    from fraud_support_tickets t
    group by cookie_id, cookie
) _
;
