create fact credit_broker_revenue as
select
    t.issued_date::date as __date__,
    t.cookie_id,
    t.is_early_closed,
    t.is_issued,
    t.issued_date,
    t.revenue,
    t.x_from_page
from DMA.v_broker_events_revenue t
;

create metrics credit_broker_revenue as
select
    sum(case when is_issued = 1 and is_early_closed is null and (x_from_page is null or x_from_page in ('landing_tinkoff', 'tinkoff')) then revenue end) as credit_auto_revenue_issue_dt,
    sum(case when is_issued = 1 and is_early_closed is null and x_from_page = 'tinkoff_cash' then revenue end) as credit_cash_revenue_issue_dt
from credit_broker_revenue t
;
