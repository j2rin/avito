create fact classified_revenue as
select
    t.event_date::date as __date__,
    *
from dma.v_paying_user_report_full_dimetra t
;

create metrics classified_revenue as
select
    sum(case when is_revenue = True and is_classified = True and product_type = 'bundle' then transaction_amount_net_adj end) as bundle_amount_net_adj,
    sum(case when is_payment = True and is_classified = True and product_type = 'bundle' then transaction_amount_net_adj end) as bundle_payments_net_adj,
    sum(case when is_revenue = True and is_classified = True and product_type = 'bundle' then transaction_count end) as bundle_transactions,
    sum(case when is_payment = True and is_classified = True and product_type = 'bundle' then transaction_count end) as bundle_transactions_p,
    sum(case when is_revenue = True and is_classified = True then transaction_amount_net_adj end) as classified_amount_net_adj,
    sum(case when is_revenue = True and is_classified = True and is_user_cpa = True then transaction_amount_net_adj end) as classified_amount_net_adj_cpa_user,
    sum(case when is_payment = True and is_classified = True then transaction_amount_net_adj end) as classified_payments_net_adj,
    sum(case when is_revenue = True and is_classified = True then transaction_count end) as classified_transactions,
    sum(case when is_payment = True and is_classified = True then transaction_count end) as classified_transactions_p,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' then cpa_target_action_count end) as cpa_action_count,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'calls' then cpa_target_action_count end) as cpa_action_count_calls,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'clicks' then cpa_target_action_count end) as cpa_action_count_clicks,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'contacts' then cpa_target_action_count end) as cpa_action_count_contacts,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'prevalidations' then cpa_target_action_count end) as cpa_action_count_prevalidations,
    sum(case when is_revenue = False and product_type = 'cpa' and product_subtype = 'calls' and transaction_subtype = 'protested in closed period' then cpa_target_action_count end) as cpa_action_count_protested_closed_calls,
    sum(case when is_revenue = False and product_type = 'cpa' and product_subtype = 'clicks' and transaction_subtype = 'protested in closed period' then cpa_target_action_count end) as cpa_action_count_protested_closed_clicks,
    sum(case when is_revenue = False and product_type = 'cpa' and product_subtype = 'contacts' and transaction_subtype = 'protested in closed period' then cpa_target_action_count end) as cpa_action_count_protested_closed_contacts,
    sum(case when is_revenue = False and product_type = 'cpa' and product_subtype = 'prevalidations' and transaction_subtype = 'protested in closed period' then cpa_target_action_count end) as cpa_action_count_protested_closed_prevalidations,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'calls' and transaction_subtype = 'protested in open period' then cpa_target_action_count end) as cpa_action_count_protested_open_calls,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'clicks' and transaction_subtype = 'protested in open period' then cpa_target_action_count end) as cpa_action_count_protested_open_clicks,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'contacts' and transaction_subtype = 'protested in open period' then cpa_target_action_count end) as cpa_action_count_protested_open_contacts,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'prevalidations' and transaction_subtype = 'protested in open period' then cpa_target_action_count end) as cpa_action_count_protested_open_prevalidations,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'calls' and transaction_subtype = 'target actions' then cpa_target_action_count end) as cpa_action_count_target_calls,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'clicks' and transaction_subtype = 'target actions' then cpa_target_action_count end) as cpa_action_count_target_clicks,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'contacts' and transaction_subtype = 'target actions' then cpa_target_action_count end) as cpa_action_count_target_contacts,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'prevalidations' and transaction_subtype = 'target actions' then cpa_target_action_count end) as cpa_action_count_target_prevalidations,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' then transaction_amount end) as cpa_amount,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' then transaction_amount_net_adj end) as cpa_amount_net_adj,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'calls' then transaction_amount_net_adj end) as cpa_amount_net_adj_calls,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'clicks' then transaction_amount_net_adj end) as cpa_amount_net_adj_clicks,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'contacts' then transaction_amount_net_adj end) as cpa_amount_net_adj_contacts,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'prevalidations' then transaction_amount_net_adj end) as cpa_amount_net_adj_prevalidations,
    sum(case when is_revenue = False and product_type = 'cpa' and product_subtype = 'calls' and transaction_subtype = 'protested in closed period' then transaction_amount_net_adj end) as cpa_amount_net_adj_protested_closed_calls,
    sum(case when is_revenue = False and product_type = 'cpa' and product_subtype = 'clicks' and transaction_subtype = 'protested in closed period' then transaction_amount_net_adj end) as cpa_amount_net_adj_protested_closed_clicks,
    sum(case when is_revenue = False and product_type = 'cpa' and product_subtype = 'contacts' and transaction_subtype = 'protested in closed period' then transaction_amount_net_adj end) as cpa_amount_net_adj_protested_closed_contacts,
    sum(case when is_revenue = False and product_type = 'cpa' and product_subtype = 'prevalidations' and transaction_subtype = 'protested in closed period' then transaction_amount_net_adj end) as cpa_amount_net_adj_protested_closed_prevalidations,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'calls' and transaction_subtype = 'protested in open period' then transaction_amount_net_adj end) as cpa_amount_net_adj_protested_open_calls,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'clicks' and transaction_subtype = 'protested in open period' then transaction_amount_net_adj end) as cpa_amount_net_adj_protested_open_clicks,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'contacts' and transaction_subtype = 'protested in open period' then transaction_amount_net_adj end) as cpa_amount_net_adj_protested_open_contacts,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'prevalidations' and transaction_subtype = 'protested in open period' then transaction_amount_net_adj end) as cpa_amount_net_adj_protested_open_prevalidations,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'calls' and transaction_subtype = 'target actions' then transaction_amount_net_adj end) as cpa_amount_net_adj_target_calls,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'clicks' and transaction_subtype = 'target actions' then transaction_amount_net_adj end) as cpa_amount_net_adj_target_clicks,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'contacts' and transaction_subtype = 'target actions' then transaction_amount_net_adj end) as cpa_amount_net_adj_target_contacts,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'prevalidations' and transaction_subtype = 'target actions' then transaction_amount_net_adj end) as cpa_amount_net_adj_target_prevalidations,
    sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' then transaction_count end) as cpa_transactions,
    sum(case when is_revenue = True and product_type = 'short_term_rent' and transaction_subtype = 'check' then transaction_amount_net_adj end) as domoteka_amount_net_adj,
    sum(case when is_revenue = True and is_classified = True and product_type = 'subscription' and product_subtype = 'extension' then transaction_amount_net_adj end) as extensions_amount_net_adj,
    sum(case when is_revenue = True and is_classified = True and product_type = 'subscription' and product_subtype = 'extension' then transaction_count end) as extensions_transactions,
    sum(case when is_revenue = True and is_classified = True and product_type = 'lf' then transaction_amount_net_adj end) as lf_amount_net_adj,
    sum(case when is_revenue = True and is_classified = True and product_type = 'lf' and is_user_cpa = True then transaction_amount_net_adj end) as lf_amount_net_adj_cpa_user,
    sum(case when is_payment = True and is_classified = True and product_type = 'lf' then transaction_amount_net_adj end) as lf_payments_net_adj,
    sum(case when is_revenue = True and is_classified = True and product_type = 'lf' then transaction_count end) as lf_transactions,
    sum(case when is_revenue = True and is_classified = True and product_type = 'lf' and is_user_cpa = True then transaction_count end) as lf_transactions_cpa_user,
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
    sum(case when is_revenue = True and is_classified = True and product_type = 'subscription' and is_user_cpa = True then transaction_amount_net_adj end) as subs_w_extensions_amount_net_adj_cpa_user,
    sum(case when is_payment = True and is_classified = True and product_type = 'subscription' then transaction_amount_net_adj end) as subs_w_extensions_payments_net_adj,
    sum(case when is_revenue = True and is_classified = True and product_type = 'subscription' then transaction_count end) as subs_w_extensions_transactions,
    sum(case when is_revenue = True and is_classified = True and product_type = 'subscription' and is_user_cpa = True then transaction_count end) as subs_w_extensions_transactions_cpa_user,
    sum(case when is_payment = True and is_classified = True and product_type = 'subscription' then transaction_count end) as subs_w_extensions_transactions_p,
    sum(case when is_revenue = True and is_classified = True and product_type = 'vas' then transaction_amount_net_adj end) as vas_amount_net_adj,
    sum(case when is_revenue = True and is_classified = True and product_type = 'vas' and is_user_cpa = True then transaction_amount_net_adj end) as vas_amount_net_adj_cpa_user,
    sum(case when is_revenue = True and is_classified = True and product_type = 'vas' and product_subtype = 'performance' and is_user_cpa = True then transaction_amount_net_adj end) as vas_amount_net_adj_performance_cpa_user,
    sum(case when is_revenue = True and is_classified = True and product_type = 'vas' and product_subtype = 'visual' and is_user_cpa = True then transaction_amount_net_adj end) as vas_amount_net_adj_visual_cpa_user,
    sum(case when is_payment = True and is_classified = True and product_type = 'vas' then transaction_amount_net_adj end) as vas_payments_net_adj,
    sum(case when is_revenue = True and is_classified = True and product_type = 'vas' then transaction_count end) as vas_transactions,
    sum(case when is_revenue = True and is_classified = True and product_type = 'vas' and is_user_cpa = True then transaction_count end) as vas_transactions_cpa_user,
    sum(case when is_payment = True and is_classified = True and product_type = 'vas' then transaction_count end) as vas_transactions_p
from classified_revenue t
;

create metrics classified_revenue_user as
select
    sum(case when classified_payments_net_adj > 0 then 1 end) as classified_payments_users,
    sum(case when classified_amount_net_adj > 0 then 1 end) as classified_users,
    sum(case when cpa_amount_net_adj > 0 then 1 end) as cpa_users,
    sum(case when cpa_amount_net_adj_calls > 0 then 1 end) as cpa_users_calls,
    sum(case when cpa_amount_net_adj_clicks > 0 then 1 end) as cpa_users_clicks,
    sum(case when cpa_amount_net_adj_contacts > 0 then 1 end) as cpa_users_contacts,
    sum(case when cpa_amount_net_adj_prevalidations > 0 then 1 end) as cpa_users_prevalidations,
    sum(case when lf_payments_net_adj > 0 then 1 end) as lf_payments_users,
    sum(case when lf_amount_net_adj > 0 then 1 end) as lf_users,
    sum(case when lf_amount_net_adj_cpa_user > 0 then 1 end) as lf_users_cpa_users,
    sum(case when pc_w_classified_amount_net_adj > 0 then 1 end) as paying_users,
    sum(case when subs_w_extensions_payments_net_adj > 0 then 1 end) as subs_extensions_payments_users,
    sum(case when subs_w_extensions_amount_net_adj > 0 then 1 end) as subs_w_extensions_users,
    sum(case when subs_w_extensions_amount_net_adj_cpa_user > 0 then 1 end) as subs_w_extensions_users_cpa_users,
    sum(case when vas_payments_net_adj > 0 then 1 end) as vas_payments_users,
    sum(case when vas_amount_net_adj_performance_cpa_user > 0 then 1 end) as vas_performance_users_cpa_users,
    sum(case when vas_amount_net_adj > 0 then 1 end) as vas_users,
    sum(case when vas_amount_net_adj_cpa_user > 0 then 1 end) as vas_users_cpa_users,
    sum(case when vas_amount_net_adj_visual_cpa_user > 0 then 1 end) as vas_visual_users_cpa_users
from (
    select
        user_id,
        sum(case when is_revenue = True and is_classified = True then transaction_amount_net_adj end) as classified_amount_net_adj,
        sum(case when is_payment = True and is_classified = True then transaction_amount_net_adj end) as classified_payments_net_adj,
        sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' then transaction_amount_net_adj end) as cpa_amount_net_adj,
        sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'calls' then transaction_amount_net_adj end) as cpa_amount_net_adj_calls,
        sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'clicks' then transaction_amount_net_adj end) as cpa_amount_net_adj_clicks,
        sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'contacts' then transaction_amount_net_adj end) as cpa_amount_net_adj_contacts,
        sum(case when is_revenue = True and is_classified = True and product_type = 'cpa' and product_subtype = 'prevalidations' then transaction_amount_net_adj end) as cpa_amount_net_adj_prevalidations,
        sum(case when is_revenue = True and is_classified = True and product_type = 'lf' then transaction_amount_net_adj end) as lf_amount_net_adj,
        sum(case when is_revenue = True and is_classified = True and product_type = 'lf' and is_user_cpa = True then transaction_amount_net_adj end) as lf_amount_net_adj_cpa_user,
        sum(case when is_payment = True and is_classified = True and product_type = 'lf' then transaction_amount_net_adj end) as lf_payments_net_adj,
        sum(case when is_revenue = True and (is_classified = True or product_type = 'paid_contact') then transaction_amount_net_adj end) as pc_w_classified_amount_net_adj,
        sum(case when is_revenue = True and is_classified = True and product_type = 'subscription' then transaction_amount_net_adj end) as subs_w_extensions_amount_net_adj,
        sum(case when is_revenue = True and is_classified = True and product_type = 'subscription' and is_user_cpa = True then transaction_amount_net_adj end) as subs_w_extensions_amount_net_adj_cpa_user,
        sum(case when is_payment = True and is_classified = True and product_type = 'subscription' then transaction_amount_net_adj end) as subs_w_extensions_payments_net_adj,
        sum(case when is_revenue = True and is_classified = True and product_type = 'vas' then transaction_amount_net_adj end) as vas_amount_net_adj,
        sum(case when is_revenue = True and is_classified = True and product_type = 'vas' and is_user_cpa = True then transaction_amount_net_adj end) as vas_amount_net_adj_cpa_user,
        sum(case when is_revenue = True and is_classified = True and product_type = 'vas' and product_subtype = 'performance' and is_user_cpa = True then transaction_amount_net_adj end) as vas_amount_net_adj_performance_cpa_user,
        sum(case when is_revenue = True and is_classified = True and product_type = 'vas' and product_subtype = 'visual' and is_user_cpa = True then transaction_amount_net_adj end) as vas_amount_net_adj_visual_cpa_user,
        sum(case when is_payment = True and is_classified = True and product_type = 'vas' then transaction_amount_net_adj end) as vas_payments_net_adj
    from classified_revenue t
    group by user_id
) _
;