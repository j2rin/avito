select
    cast(created_txtime as date) as create_date,
    payment_transaction_id,
    user_id,
    null as platform_id,
    amount,
    status=2 as is_paid
from dma.current_payment_transactions
where
    amount > 0
    and transaction_type = 'payout'
    and cast(created_txtime as date) between :first_date and :last_date
    and payment_project = 'MARKETPLACE'
