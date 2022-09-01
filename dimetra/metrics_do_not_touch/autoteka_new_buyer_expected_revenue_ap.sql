create fact autoteka_new_buyer_expected_revenue_ap as
select
    t.event_date::date as __date__,
    *
from dma.v_autoteka_new_buyers_expected_revenue t
;

create metrics autoteka_new_buyer_expected_revenue_ap as
select
    sum(reports_next_365_days_left) as reports_next_365_days_left_ap,
    sum(revenue_next_365_days_left) as revenue_next_365_days_left_ap
from autoteka_new_buyer_expected_revenue_ap t
;
