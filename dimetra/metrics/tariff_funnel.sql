create fact tariff_funnel as
select
    t.event_date::date as __date__,
    t.configurator_source,
    t.event_date,
    t.step,
    t.user_id
from dma.vo_tariff_metrics_funnel t
;

create metrics tariff_funnel as
select
    sum(case when step = 'configurator' and (configurator_source != 'item activation' or configurator_source is null) then 1 end) as cnt_tariff_config_openconfig,
    sum(case when step = 'purchase' and (configurator_source != 'item activation' or configurator_source is null) then 1 end) as cnt_tariff_config_purchase,
    sum(case when step = 'configurator submit' and (configurator_source != 'item activation' or configurator_source is null) then 1 end) as cnt_tariff_config_submit,
    sum(case when configurator_source = 'item activation' and step = 'configurator' then 1 end) as cnt_tariff_itemactivation_openconfig,
    sum(case when configurator_source = 'item activation' and step = 'purchase' then 1 end) as cnt_tariff_itemactivation_purchase,
    sum(case when configurator_source = 'item activation' and step = 'item activation' then 1 end) as cnt_tariff_itemactivation_start,
    sum(case when configurator_source = 'item activation' and step = 'configurator submit' then 1 end) as cnt_tariff_itemactivation_submit,
    sum(case when step = 'configurator' then 1 end) as cnt_tariff_openconfig,
    sum(case when step = 'purchase' then 1 end) as cnt_tariff_purchase,
    sum(case when step = 'configurator submit' then 1 end) as cnt_tariff_submit
from tariff_funnel t
;

create metrics tariff_funnel_user_id as
select
    sum(case when cnt_tariff_config_openconfig > 0 then 1 end) as users_tariff_config_openconfig,
    sum(case when cnt_tariff_config_purchase > 0 then 1 end) as users_tariff_config_purchase,
    sum(case when cnt_tariff_config_submit > 0 then 1 end) as users_tariff_config_submit,
    sum(case when cnt_tariff_itemactivation_openconfig > 0 then 1 end) as users_tariff_itemactivation_openconfig,
    sum(case when cnt_tariff_itemactivation_purchase > 0 then 1 end) as users_tariff_itemactivation_purchase,
    sum(case when cnt_tariff_itemactivation_start > 0 then 1 end) as users_tariff_itemactivation_start,
    sum(case when cnt_tariff_itemactivation_submit > 0 then 1 end) as users_tariff_itemactivation_submit,
    sum(case when cnt_tariff_openconfig > 0 then 1 end) as users_tariff_openconfig,
    sum(case when cnt_tariff_purchase > 0 then 1 end) as users_tariff_purchase,
    sum(case when cnt_tariff_submit > 0 then 1 end) as users_tariff_submit
from (
    select
        user_id, user_id,
        sum(case when step = 'configurator' and (configurator_source != 'item activation' or configurator_source is null) then 1 end) as cnt_tariff_config_openconfig,
        sum(case when step = 'purchase' and (configurator_source != 'item activation' or configurator_source is null) then 1 end) as cnt_tariff_config_purchase,
        sum(case when step = 'configurator submit' and (configurator_source != 'item activation' or configurator_source is null) then 1 end) as cnt_tariff_config_submit,
        sum(case when configurator_source = 'item activation' and step = 'configurator' then 1 end) as cnt_tariff_itemactivation_openconfig,
        sum(case when configurator_source = 'item activation' and step = 'purchase' then 1 end) as cnt_tariff_itemactivation_purchase,
        sum(case when configurator_source = 'item activation' and step = 'item activation' then 1 end) as cnt_tariff_itemactivation_start,
        sum(case when configurator_source = 'item activation' and step = 'configurator submit' then 1 end) as cnt_tariff_itemactivation_submit,
        sum(case when step = 'configurator' then 1 end) as cnt_tariff_openconfig,
        sum(case when step = 'purchase' then 1 end) as cnt_tariff_purchase,
        sum(case when step = 'configurator submit' then 1 end) as cnt_tariff_submit
    from tariff_funnel t
    group by user_id, user_id
) _
;
