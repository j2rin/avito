create fact autoteka_new_buyer_expected_revenue as
select
    t.event_date::date as __date__,
    *
from dma.v_autoteka_new_buyers_expected_revenue t
;

create metrics autoteka_new_buyer_expected_revenue as
select
    sum(reports_next_365_days_left) as reports_next_365_days_left,
    sum(revenue_next_365_days_left) as revenue_next_365_days_left
from autoteka_new_buyer_expected_revenue t
;
