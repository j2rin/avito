create fact mnz_bundle as
select
    t.event_date::date as __date__,
    t.amount_net_adj,
    t.event_date,
    t.exposure,
    t.exposure_eventtype,
    t.first_day_transaction_count,
    t.is_tariff_user,
    t.transaction_type,
    t.user_id
from dma.vo_mnz_bundle t
;

create metrics mnz_bundle as
select
    sum(case when transaction_type in ('bundle reserve', 'bundle return') and is_tariff_user = False then amount_net_adj end) as bdl_bundle_clean_reserved_revenue,
    sum(case when exposure_eventtype = 'bundle show' and is_tariff_user = False then exposure end) as bdl_bundle_exposure,
    sum(case when exposure_eventtype = 'bundle show' and is_tariff_user = False then first_day_transaction_count end) as bdl_bundle_first_day_transactions,
    sum(case when exposure_eventtype = 'bundle or vas show' and is_tariff_user = False then exposure end) as bdl_bundle_or_vas_exposure,
    sum(case when exposure_eventtype = 'bundle or vas show' and is_tariff_user = False then first_day_transaction_count end) as bdl_bundle_or_vas_first_day_transactions,
    sum(case when transaction_type = 'bundle write off' and is_tariff_user = False then amount_net_adj end) as bdl_bundle_revenue,
    sum(case when transaction_type = 'Bundle VAS write off' and is_tariff_user = False then amount_net_adj end) as bdl_bundle_vas_revenue,
    sum(case when transaction_type = 'listing.fee' and is_tariff_user = False then amount_net_adj end) as bdl_lf_revenue,
    sum(case when transaction_type in ('Bundle VAS reserve', 'Bundle VAS return', 'Performance VAS reserve', 'Performance VAS return', 'VAS', 'VAS reserve', 'VAS return', 'bundle reserve', 'bundle return', 'listing.fee') and is_tariff_user = False then amount_net_adj end) as bdl_total_clean_reserved_revenue,
    sum(case when transaction_type in ('Bundle VAS write off', 'Performance VAS write off', 'VAS', 'VAS write off', 'bundle write off', 'listing.fee') and is_tariff_user = False then amount_net_adj end) as bdl_total_revenue,
    sum(case when transaction_type in ('Bundle VAS write off', 'Performance VAS write off', 'VAS', 'VAS write off', 'bundle write off') and is_tariff_user = False then amount_net_adj end) as bdl_vas_and_bundle_revenue,
    sum(case when transaction_type in ('Performance VAS write off', 'VAS', 'VAS write off') and is_tariff_user = False then amount_net_adj end) as bdl_vas_revenue
from mnz_bundle t
;

create metrics mnz_bundle_user_id as
select
    sum(case when bdl_bundle_revenue > 0 then 1 end) as bdl_bundle_users,
    sum(case when bdl_bundle_vas_revenue > 0 then 1 end) as bdl_bundle_vas_users,
    sum(case when bdl_vas_and_bundle_revenue > 0 then 1 end) as bdl_vas_or_bundle_users
from (
    select
        user_id, user_id,
        sum(case when transaction_type = 'bundle write off' and is_tariff_user = False then amount_net_adj end) as bdl_bundle_revenue,
        sum(case when transaction_type = 'Bundle VAS write off' and is_tariff_user = False then amount_net_adj end) as bdl_bundle_vas_revenue,
        sum(case when transaction_type in ('Bundle VAS write off', 'Performance VAS write off', 'VAS', 'VAS write off', 'bundle write off') and is_tariff_user = False then amount_net_adj end) as bdl_vas_and_bundle_revenue
    from mnz_bundle t
    group by user_id, user_id
) _
;
