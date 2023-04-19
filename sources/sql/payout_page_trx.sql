select
    created_txtime::date as create_date,
    payment_transaction_id,
    user_id,
    amount,
    status=2 as is_paid
from dma.current_payment_transactions
where
    amount > 0
    and transaction_type = 'payout'
    and created_txtime between :first_date and :last_date
    and payment_project = 'MARKETPLACE'
