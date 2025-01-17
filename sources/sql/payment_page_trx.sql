select 
    cast(pp.transaction_date as date) as event_date,
    pp.payment_transaction_id,
    pp.cookie_id,
    pp.user_id,
    pp.platform_id,
    pp.order_ext,
    pp.billing_order_id,
    pp.autoteka_billing_order_id,
    pp.order_id,
    pp.pay_page_trx_create,
    pp.pay_form_submit,
    pp.sent_to_3ds,
    pp.pay_form_render,
    pp.input_focused,
    pp.input_start_filling,
    pp.input_filled_correctly,
    pp.input_filled_incorrectly,
    pp.payform_validation_failed,
    cpt.status,
    cpt.amount,
    cpt.commission,
    cpt.transaction_type,
    cpt.payment_project,
    cpt.provider,
    cpt.provider_preset,
    cpt.payment_plan,
    coalesce(cpt.payment_method,'other') payment_method,
    coalesce(cpt.payment_method,'other') = 'SBP' as is_sbp,
    cpt.linked_source_id,
    coalesce(cpt.provider_payment_number, cpt.payment_linked_source) as payment_number,
    coalesce(ec.errorcode,'0') errorcode
from dma.payment_page_transaction_funnel pp 
join dma.current_payment_transactions cpt on cpt.payment_transaction_id = pp.payment_transaction_id
left join dds.S_PaymentTransaction_ErrorCode ec on cpt.payment_transaction_id = ec.paymenttransaction_id
where cast(pp.transaction_date as date) between :first_date and :last_date
-- and transaction_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
