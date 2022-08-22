create fact total_revenue as
select
    t.event_date::date as __date__,
    *
from dma.vo_total_revenue t
;

create metrics total_revenue as
select
    sum(case when (is_classified = True or product_type = 'paid_contact' or project_type = 'advertisement') then amount_net_adj end) as avito_amount_net_adj,
    sum(case when (product_type = 'short_term_rent' and transaction_subtype = 'check' or product_type = 'short_term_rent' and transaction_subtype = 'buyer book' or project_type in ('autoteka', 'delivery', 'domofond')) then amount_net_adj end) as other_projects_amount_net_adj,
    sum(case when (is_classified = True or product_type = 'paid_contact' or product_type = 'short_term_rent' and transaction_subtype = 'check' or product_type = 'short_term_rent' and transaction_subtype = 'buyer book' or project_type in ('advertisement', 'autoteka', 'delivery', 'domofond')) then amount_net_adj end) as total_amount_net_adj
from total_revenue t
;
