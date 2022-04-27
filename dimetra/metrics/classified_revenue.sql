create fact classified_revenue as
select
    t.event_date,
    t.is_classified,
    t.is_payment,
    t.is_revenue,
    t.product_subtype,
    t.product_type,
    t.transaction_amount,
    t.transaction_amount_net,
    t.transaction_amount_net_adj,
    t.transaction_count,
    t.transaction_subtype,
    t.user_id as user,
    t.user_id
from dma.v_paying_user_report_full t
;

create metrics classified_revenue as
select
    sum(case when is_revenue = True and is_classified = True and product_type = 'bundle' then transaction_amount_net_adj end) as bundle_amount_net_adj,
    sum(case when is_payment = True and is_classified = True and product_type = 'bundle' then transaction_amount_net_adj end) as bundle_payments_net_adj,
    sum(case when is_revenue = True and is_classified = True and product_type = 'bundle' then transaction_count end) as bundle_transactions,
    sum(case when is_payment = True and is_classified = True and product_type = 'bundle' then transaction_count end) as bundle_transactions_p,
    sum(case when is_revenue = True and is_classified = True then transaction_amount_net_adj end) as classified_amount_net_adj,
    sum(case when is_payment = True and is_classified = True then transaction_amount_net_adj end) as classified_payments_net_adj,
    sum(case when is_revenue = True and is_classified = True then transaction_count end) as classified_transactions,
    sum(case when is_payment = True and is_classified = True then transaction_count end) as classified_transactions_p,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' then transaction_amount_net_adj end) as cpa_amount_net_adj,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' then transaction_count end) as cpa_transactions,
    sum(case when is_revenue = True and product_type = 'short_term_rent' and transaction_subtype = 'check' then transaction_amount_net_adj end) as domoteka_amount_net_adj,
    sum(case when is_revenue = True and is_classified = True and product_type = 'subscription' and product_subtype = 'extension' then transaction_amount_net_adj end) as extensions_amount_net_adj,
    sum(case when is_revenue = True and is_classified = True and product_type = 'subscription' and product_subtype = 'extension' then transaction_count end) as extensions_transactions,
    sum(case when is_revenue = True and is_classified = True and product_type = 'lf' then transaction_amount_net_adj end) as lf_amount_net_adj,
    sum(case when is_payment = True and is_classified = True and product_type = 'lf' then transaction_amount_net_adj end) as lf_payments_net_adj,
    sum(case when is_revenue = True and is_classified = True and product_type = 'lf' then transaction_count end) as lf_transactions,
    sum(case when is_payment = True and is_classified = True and product_type = 'lf' then transaction_count end) as lf_transactions_p,
    sum(case when is_revenue = True and product_type = 'paid_contact' then transaction_amount_net_adj end) as paid_contact_amount_net_adj,
    sum(case when is_revenue = True and (is_classified = True or product_type = 'paid_contact') then transaction_amount_net_adj end) as pc_w_classified_amount_net_adj,
    sum(case when is_revenue = True then transaction_amount_net_adj end) as revenue_net_adj_total,
    sum(case when is_revenue = True then transaction_amount_net end) as revenue_net_total,
    sum(case when is_revenue = True then transaction_amount end) as revenue_total,
    sum(case when is_revenue = True and product_type = 'short_term_rent' and transaction_subtype = 'buyer book' then transaction_amount_net_adj end) as str_amount_net_adj,
    sum(case when is_revenue = True and is_classified = True and product_type = 'subscription' and product_subtype != 'extension' then transaction_amount_net_adj end) as subs_amount_net_adj,
    sum(case when is_revenue = True and is_classified = True and product_type = 'subscription' and product_subtype != 'extension' then transaction_count end) as subs_transactions,
    sum(case when is_revenue = True and is_classified = True and product_type = 'subscription' then transaction_amount_net_adj end) as subs_w_extensions_amount_net_adj,
    sum(case when is_payment = True and is_classified = True and product_type = 'subscription' then transaction_amount_net_adj end) as subs_w_extensions_payments_net_adj,
    sum(case when is_revenue = True and is_classified = True and product_type = 'subscription' then transaction_count end) as subs_w_extensions_transactions,
    sum(case when is_payment = True and is_classified = True and product_type = 'subscription' then transaction_count end) as subs_w_extensions_transactions_p,
    sum(case when is_revenue = True and is_classified = True and product_type = 'vas' then transaction_amount_net_adj end) as vas_amount_net_adj,
    sum(case when is_payment = True and is_classified = True and product_type = 'vas' then transaction_amount_net_adj end) as vas_payments_net_adj,
    sum(case when is_revenue = True and is_classified = True and product_type = 'vas' then transaction_count end) as vas_transactions,
    sum(case when is_payment = True and is_classified = True and product_type = 'vas' then transaction_count end) as vas_transactions_p
from classified_revenue t
;

create metrics classified_revenue_user as
select
    sum(case when classified_payments_net_adj > 0 then 1 end) as classified_payments_users,
    sum(case when classified_amount_net_adj > 0 then 1 end) as classified_users,
    sum(case when cpa_amount_net_adj > 0 then 1 end) as cpa_users,
    sum(case when lf_payments_net_adj > 0 then 1 end) as lf_payments_users,
    sum(case when lf_amount_net_adj > 0 then 1 end) as lf_users,
    sum(case when pc_w_classified_amount_net_adj > 0 then 1 end) as paying_users,
    sum(case when subs_w_extensions_payments_net_adj > 0 then 1 end) as subs_extensions_payments_users,
    sum(case when subs_w_extensions_amount_net_adj > 0 then 1 end) as subs_w_extensions_users,
    sum(case when vas_payments_net_adj > 0 then 1 end) as vas_payments_users,
    sum(case when vas_amount_net_adj > 0 then 1 end) as vas_users
from (
    select
        user_id, user,
        sum(case when is_revenue = True and is_classified = True then transaction_amount_net_adj end) as classified_amount_net_adj,
        sum(case when is_payment = True and is_classified = True then transaction_amount_net_adj end) as classified_payments_net_adj,
        sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' then transaction_amount_net_adj end) as cpa_amount_net_adj,
        sum(case when is_revenue = True and is_classified = True and product_type = 'lf' then transaction_amount_net_adj end) as lf_amount_net_adj,
        sum(case when is_payment = True and is_classified = True and product_type = 'lf' then transaction_amount_net_adj end) as lf_payments_net_adj,
        sum(case when is_revenue = True and (is_classified = True or product_type = 'paid_contact') then transaction_amount_net_adj end) as pc_w_classified_amount_net_adj,
        sum(case when is_revenue = True and is_classified = True and product_type = 'subscription' then transaction_amount_net_adj end) as subs_w_extensions_amount_net_adj,
        sum(case when is_payment = True and is_classified = True and product_type = 'subscription' then transaction_amount_net_adj end) as subs_w_extensions_payments_net_adj,
        sum(case when is_revenue = True and is_classified = True and product_type = 'vas' then transaction_amount_net_adj end) as vas_amount_net_adj,
        sum(case when is_payment = True and is_classified = True and product_type = 'vas' then transaction_amount_net_adj end) as vas_payments_net_adj
    from classified_revenue t
    group by user_id, user
) _
;
