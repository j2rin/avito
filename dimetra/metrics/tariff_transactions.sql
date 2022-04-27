create fact tariff_transactions as
select
    t.amount,
    t.event_date,
    t.tariff_source,
    t.transaction_type,
    t.user_id
from dma.vo_lf_metrics_transactions t
;

create metrics tariff_transactions as
select
    sum(case when transaction_type = 'subscription burned' then amount end) as tariff_burned_amount,
    sum(case when transaction_type = 'subscription burned' and tariff_source = 'configurator' then amount end) as tariff_config_burned_amount,
    sum(case when transaction_type = 'subscription pay in' and tariff_source = 'configurator' then amount end) as tariff_config_payin_amount,
    sum(case when transaction_type = 'subscription return' and tariff_source = 'configurator' then amount end) as tariff_config_return_amount,
    sum(case when transaction_type = 'subscription upgrade' and tariff_source = 'configurator' then amount end) as tariff_config_upgrade_amount,
    sum(case when transaction_type = 'subscription burned' and tariff_source = 'item activation' then amount end) as tariff_itemactivation_burned_amount,
    sum(case when transaction_type = 'subscription pay in' and tariff_source = 'item activation' then amount end) as tariff_itemactivation_payin_amount,
    sum(case when transaction_type = 'subscription return' and tariff_source = 'item activation' then amount end) as tariff_itemactivation_return_amount,
    sum(case when transaction_type = 'subscription upgrade' and tariff_source = 'item activation' then amount end) as tariff_itemactivation_upgrade_amount,
    sum(case when transaction_type = 'subscription pay in' then amount end) as tariff_payin_amount,
    sum(case when transaction_type = 'subscription return' then amount end) as tariff_return_amount,
    sum(case when transaction_type = 'subscription upgrade' then amount end) as tariff_upgrade_amount
from tariff_transactions t
;

create metrics tariff_transactions_user_id as
select
    sum(case when tariff_burned_amount > 0 then 1 end) as tariff_burned_users,
    sum(case when tariff_config_burned_amount > 0 then 1 end) as tariff_config_burned_users,
    sum(case when tariff_config_payin_amount > 0 then 1 end) as tariff_config_payin_users,
    sum(case when tariff_config_return_amount > 0 then 1 end) as tariff_config_return_users,
    sum(case when tariff_config_upgrade_amount > 0 then 1 end) as tariff_config_upgrade_users,
    sum(case when tariff_itemactivation_burned_amount > 0 then 1 end) as tariff_itemactivation_burned_users,
    sum(case when tariff_itemactivation_payin_amount > 0 then 1 end) as tariff_itemactivation_payin_users,
    sum(case when tariff_itemactivation_return_amount > 0 then 1 end) as tariff_itemactivation_return_users,
    sum(case when tariff_itemactivation_upgrade_amount > 0 then 1 end) as tariff_itemactivation_upgrade_users,
    sum(case when tariff_payin_amount > 0 then 1 end) as tariff_payin_users,
    sum(case when tariff_return_amount > 0 then 1 end) as tariff_return_users,
    sum(case when tariff_upgrade_amount > 0 then 1 end) as tariff_upgrade_users
from (
    select
        user_id, user_id,
        sum(case when transaction_type = 'subscription burned' then amount end) as tariff_burned_amount,
        sum(case when transaction_type = 'subscription burned' and tariff_source = 'configurator' then amount end) as tariff_config_burned_amount,
        sum(case when transaction_type = 'subscription pay in' and tariff_source = 'configurator' then amount end) as tariff_config_payin_amount,
        sum(case when transaction_type = 'subscription return' and tariff_source = 'configurator' then amount end) as tariff_config_return_amount,
        sum(case when transaction_type = 'subscription upgrade' and tariff_source = 'configurator' then amount end) as tariff_config_upgrade_amount,
        sum(case when transaction_type = 'subscription burned' and tariff_source = 'item activation' then amount end) as tariff_itemactivation_burned_amount,
        sum(case when transaction_type = 'subscription pay in' and tariff_source = 'item activation' then amount end) as tariff_itemactivation_payin_amount,
        sum(case when transaction_type = 'subscription return' and tariff_source = 'item activation' then amount end) as tariff_itemactivation_return_amount,
        sum(case when transaction_type = 'subscription upgrade' and tariff_source = 'item activation' then amount end) as tariff_itemactivation_upgrade_amount,
        sum(case when transaction_type = 'subscription pay in' then amount end) as tariff_payin_amount,
        sum(case when transaction_type = 'subscription return' then amount end) as tariff_return_amount,
        sum(case when transaction_type = 'subscription upgrade' then amount end) as tariff_upgrade_amount
    from tariff_transactions t
    group by user_id, user_id
) _
;
