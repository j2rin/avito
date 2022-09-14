create fact listing_fees as
select
    t.event_date::date as __date__,
    *
from dma.vo_lf_metrics t
;

create metrics listing_fees as
select
    sum(paid_activations_count) as lf_activations,
    sum(amount) as lf_revenue,
    sum(amount_net) as lf_revenue_net,
    sum(amount_net_adj) as lf_revenue_net_adj,
    sum(1) as lf_users_counter,
    sum(case when tariff_type = 'single' then paid_activations_count end) as single_listing_activations,
    sum(case when tariff_type = 'single' then amount end) as single_listing_revenue,
    sum(case when tariff_type = 'single' then 1 end) as single_users_counter,
    sum(case when tariff_type = 'tariff' then paid_activations_count end) as tariff_activations,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'base' then paid_activations_count end) as tariff_base_activations,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'base' then amount end) as tariff_base_revenue,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'base' then 1 end) as tariff_base_users_counter,
    sum(case when tariff_type = 'tariff' and tariff_source = 'configurator' then paid_activations_count end) as tariff_config_activations,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'base' and tariff_source = 'configurator' then paid_activations_count end) as tariff_config_base_activations,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'base' and tariff_source = 'configurator' then amount end) as tariff_config_base_revenue,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'base' and tariff_source = 'configurator' then 1 end) as tariff_config_base_users_counter,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'ext' and tariff_source = 'configurator' then paid_activations_count end) as tariff_config_ext_activations,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'ext' and tariff_source = 'configurator' then amount end) as tariff_config_ext_revenue,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'ext' and tariff_source = 'configurator' then 1 end) as tariff_config_ext_users_counter,
    sum(case when tariff_type = 'tariff' and tariff_source = 'configurator' then amount_tariff_level end) as tariff_config_level_revenue,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'max' and tariff_source = 'configurator' then paid_activations_count end) as tariff_config_max_activations,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'max' and tariff_source = 'configurator' then amount end) as tariff_config_max_revenue,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'max' and tariff_source = 'configurator' then 1 end) as tariff_config_max_users_counter,
    sum(case when tariff_type = 'tariff' and tariff_source = 'configurator' then amount_tariff_package end) as tariff_config_package_revenue,
    sum(case when tariff_type = 'tariff' and tariff_subtype != 'base' and tariff_source = 'configurator' then paid_activations_count end) as tariff_config_pro_activations,
    sum(case when tariff_type = 'tariff' and tariff_subtype != 'base' and tariff_source = 'configurator' then amount end) as tariff_config_pro_revenue,
    sum(case when tariff_type = 'tariff' and tariff_subtype != 'base' and tariff_source = 'configurator' then 1 end) as tariff_config_pro_users_counter,
    sum(case when tariff_type = 'tariff' and tariff_source = 'configurator' then amount end) as tariff_config_revenue,
    sum(case when tariff_type = 'tariff' and tariff_source = 'configurator' then 1 end) as tariff_config_users_counter,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'ext' then paid_activations_count end) as tariff_ext_activations,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'ext' then amount end) as tariff_ext_revenue,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'ext' then 1 end) as tariff_ext_users_counter,
    sum(case when tariff_type = 'tariff' and tariff_source = 'item activation' then paid_activations_count end) as tariff_itemactivation_activations,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'base' and tariff_source = 'item activation' then paid_activations_count end) as tariff_itemactivation_base_activations,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'base' and tariff_source = 'item activation' then amount end) as tariff_itemactivation_base_revenue,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'base' and tariff_source = 'item activation' then 1 end) as tariff_itemactivation_base_users_counter,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'ext' and tariff_source = 'item activation' then paid_activations_count end) as tariff_itemactivation_ext_activations,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'ext' and tariff_source = 'item activation' then amount end) as tariff_itemactivation_ext_revenue,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'ext' and tariff_source = 'item activation' then 1 end) as tariff_itemactivation_ext_users_counter,
    sum(case when tariff_type = 'tariff' and tariff_source = 'item activation' then amount_tariff_level end) as tariff_itemactivation_level_revenue,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'max' and tariff_source = 'item activation' then paid_activations_count end) as tariff_itemactivation_max_activations,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'max' and tariff_source = 'item activation' then amount end) as tariff_itemactivation_max_revenue,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'max' and tariff_source = 'item activation' then 1 end) as tariff_itemactivation_max_users_counter,
    sum(case when tariff_type = 'tariff' and tariff_source = 'item activation' then amount_tariff_package end) as tariff_itemactivation_package_revenue,
    sum(case when tariff_type = 'tariff' and tariff_subtype != 'base' and tariff_source = 'item activation' then paid_activations_count end) as tariff_itemactivation_pro_activations,
    sum(case when tariff_type = 'tariff' and tariff_subtype != 'base' and tariff_source = 'item activation' then amount end) as tariff_itemactivation_pro_revenue,
    sum(case when tariff_type = 'tariff' and tariff_subtype != 'base' and tariff_source = 'item activation' then 1 end) as tariff_itemactivation_pro_users_counter,
    sum(case when tariff_type = 'tariff' and tariff_source = 'item activation' then amount end) as tariff_itemactivation_revenue,
    sum(case when tariff_type = 'tariff' and tariff_source = 'item activation' then 1 end) as tariff_itemactivation_users_counter,
    sum(case when tariff_type = 'tariff' then amount_tariff_level end) as tariff_level_revenue,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'max' then paid_activations_count end) as tariff_max_activations,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'max' then amount end) as tariff_max_revenue,
    sum(case when tariff_type = 'tariff' and tariff_subtype = 'max' then 1 end) as tariff_max_users_counter,
    sum(case when tariff_type = 'tariff' then amount_tariff_package end) as tariff_package_revenue,
    sum(case when tariff_type = 'tariff' and tariff_subtype != 'base' then paid_activations_count end) as tariff_pro_activations,
    sum(case when tariff_type = 'tariff' and tariff_subtype != 'base' then amount end) as tariff_pro_revenue,
    sum(case when tariff_type = 'tariff' and tariff_subtype != 'base' then 1 end) as tariff_pro_users_counter,
    sum(case when tariff_type = 'tariff' then amount end) as tariff_revenue,
    sum(case when tariff_type = 'tariff' then 1 end) as tariff_users_counter
from listing_fees t
;

create metrics listing_fees_user_id as
select
    sum(case when lf_users_counter > 0 then 1 end) as lf_users_count,
    sum(case when single_users_counter > 0 then 1 end) as single_listing_users,
    sum(case when tariff_base_users_counter > 0 then 1 end) as tariff_base_users,
    sum(case when tariff_config_base_users_counter > 0 then 1 end) as tariff_config_base_users,
    sum(case when tariff_config_ext_users_counter > 0 then 1 end) as tariff_config_ext_users,
    sum(case when tariff_config_max_users_counter > 0 then 1 end) as tariff_config_max_users,
    sum(case when tariff_config_pro_users_counter > 0 then 1 end) as tariff_config_pro_users,
    sum(case when tariff_config_users_counter > 0 then 1 end) as tariff_config_users,
    sum(case when tariff_ext_users_counter > 0 then 1 end) as tariff_ext_users,
    sum(case when tariff_itemactivation_base_users_counter > 0 then 1 end) as tariff_itemactivation_base_users,
    sum(case when tariff_itemactivation_ext_users_counter > 0 then 1 end) as tariff_itemactivation_ext_users,
    sum(case when tariff_itemactivation_max_users_counter > 0 then 1 end) as tariff_itemactivation_max_users,
    sum(case when tariff_itemactivation_pro_users_counter > 0 then 1 end) as tariff_itemactivation_pro_users,
    sum(case when tariff_itemactivation_users_counter > 0 then 1 end) as tariff_itemactivation_users,
    sum(case when tariff_max_users_counter > 0 then 1 end) as tariff_max_users,
    sum(case when tariff_pro_users_counter > 0 then 1 end) as tariff_pro_users,
    sum(case when tariff_users_counter > 0 then 1 end) as tariff_users
from (
    select
        user_id,
        sum(1) as lf_users_counter,
        sum(case when tariff_type = 'single' then 1 end) as single_users_counter,
        sum(case when tariff_type = 'tariff' and tariff_subtype = 'base' then 1 end) as tariff_base_users_counter,
        sum(case when tariff_type = 'tariff' and tariff_subtype = 'base' and tariff_source = 'configurator' then 1 end) as tariff_config_base_users_counter,
        sum(case when tariff_type = 'tariff' and tariff_subtype = 'ext' and tariff_source = 'configurator' then 1 end) as tariff_config_ext_users_counter,
        sum(case when tariff_type = 'tariff' and tariff_subtype = 'max' and tariff_source = 'configurator' then 1 end) as tariff_config_max_users_counter,
        sum(case when tariff_type = 'tariff' and tariff_subtype != 'base' and tariff_source = 'configurator' then 1 end) as tariff_config_pro_users_counter,
        sum(case when tariff_type = 'tariff' and tariff_source = 'configurator' then 1 end) as tariff_config_users_counter,
        sum(case when tariff_type = 'tariff' and tariff_subtype = 'ext' then 1 end) as tariff_ext_users_counter,
        sum(case when tariff_type = 'tariff' and tariff_subtype = 'base' and tariff_source = 'item activation' then 1 end) as tariff_itemactivation_base_users_counter,
        sum(case when tariff_type = 'tariff' and tariff_subtype = 'ext' and tariff_source = 'item activation' then 1 end) as tariff_itemactivation_ext_users_counter,
        sum(case when tariff_type = 'tariff' and tariff_subtype = 'max' and tariff_source = 'item activation' then 1 end) as tariff_itemactivation_max_users_counter,
        sum(case when tariff_type = 'tariff' and tariff_subtype != 'base' and tariff_source = 'item activation' then 1 end) as tariff_itemactivation_pro_users_counter,
        sum(case when tariff_type = 'tariff' and tariff_source = 'item activation' then 1 end) as tariff_itemactivation_users_counter,
        sum(case when tariff_type = 'tariff' and tariff_subtype = 'max' then 1 end) as tariff_max_users_counter,
        sum(case when tariff_type = 'tariff' and tariff_subtype != 'base' then 1 end) as tariff_pro_users_counter,
        sum(case when tariff_type = 'tariff' then 1 end) as tariff_users_counter
    from listing_fees t
    group by user_id
) _
;