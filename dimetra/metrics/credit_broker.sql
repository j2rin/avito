create fact credit_broker as
select
    t.event_date as __date__,
    t.cookie_id,
    t.event_count,
    t.event_date,
    t.event_name_slug,
    t.eventtype_ext,
    t.is_early_closed,
    t.is_issued,
    t.revenue,
    t.x_from_page
from DMA.v_broker_events_revenue t
;

create metrics credit_broker_cookie_id as
select
    sum(case when credit_auto_full_approvals > 0 then 1 end) as credit_auto_approvals,
    sum(case when credit_auto_full_clicks > 0 then 1 end) as credit_auto_clicks,
    sum(case when credit_auto_full_fillings > 0 then 1 end) as credit_auto_fillings,
    sum(case when credit_auto_full_issues > 0 then 1 end) as credit_auto_issues,
    sum(case when credit_auto_full_loads > 0 then 1 end) as credit_auto_loads,
    sum(case when credit_auto_full_logo_clicks > 0 then 1 end) as credit_auto_logo_clicks,
    sum(case when credit_auto_full_renders > 0 then 1 end) as credit_auto_renders,
    sum(case when credit_auto_full_requests > 0 then 1 end) as credit_auto_requests,
    sum(case when credit_cash_full_approvals > 0 then 1 end) as credit_cash_approvals,
    sum(case when credit_cash_full_clicks > 0 then 1 end) as credit_cash_clicks,
    sum(case when credit_cash_full_fillings > 0 then 1 end) as credit_cash_fillings,
    sum(case when credit_cash_full_issues > 0 then 1 end) as credit_cash_issues,
    sum(case when credit_cash_full_loads > 0 then 1 end) as credit_cash_loads,
    sum(case when credit_cash_full_logo_clicks > 0 then 1 end) as credit_cash_logo_clicks,
    sum(case when credit_cash_full_renders > 0 then 1 end) as credit_cash_renders,
    sum(case when credit_cash_full_requests > 0 then 1 end) as credit_cash_requests
from (
    select
        cookie_id, cookie_id,
        sum(case when event_name_slug = 'broker_credit_approved' and (x_from_page is null or x_from_page in ('landing_tinkoff', 'tinkoff')) then 1 end) as credit_auto_full_approvals,
        sum(case when eventtype_ext = 4498 and (x_from_page is null or x_from_page in ('landing_tinkoff', 'tinkoff')) then event_count end) as credit_auto_full_clicks,
        sum(case when eventtype_ext = 4590 and (x_from_page is null or x_from_page in ('landing_tinkoff', 'tinkoff')) then event_count end) as credit_auto_full_fillings,
        sum(case when is_issued = 1 and (x_from_page is null or x_from_page in ('landing_tinkoff', 'tinkoff')) then 1 end) as credit_auto_full_issues,
        sum(case when eventtype_ext = 5283 and (x_from_page is null or x_from_page in ('landing_tinkoff', 'tinkoff')) then event_count end) as credit_auto_full_loads,
        sum(case when eventtype_ext = 4801 and (x_from_page is null or x_from_page in ('landing_tinkoff', 'tinkoff')) then event_count end) as credit_auto_full_logo_clicks,
        sum(case when eventtype_ext = 4496 and (x_from_page is null or x_from_page in ('landing_tinkoff', 'tinkoff')) then event_count end) as credit_auto_full_renders,
        sum(case when eventtype_ext = 4502 and (x_from_page is null or x_from_page in ('landing_tinkoff', 'tinkoff')) then event_count end) as credit_auto_full_requests,
        sum(case when event_name_slug = 'broker_credit_approved' and x_from_page in ('sravni_cash', 'tinkoff_cash') then 1 end) as credit_cash_full_approvals,
        sum(case when eventtype_ext = 4498 and x_from_page in ('sravni_cash', 'tinkoff_cash') then event_count end) as credit_cash_full_clicks,
        sum(case when eventtype_ext = 4590 and x_from_page in ('sravni_cash', 'tinkoff_cash') then event_count end) as credit_cash_full_fillings,
        sum(case when is_issued = 1 and x_from_page in ('sravni_cash', 'tinkoff_cash') then 1 end) as credit_cash_full_issues,
        sum(case when eventtype_ext = 5283 and x_from_page in ('sravni_cash', 'tinkoff_cash') then event_count end) as credit_cash_full_loads,
        sum(case when eventtype_ext = 4801 and x_from_page in ('sravni_cash', 'tinkoff_cash') then event_count end) as credit_cash_full_logo_clicks,
        sum(case when eventtype_ext = 4496 and x_from_page in ('sravni_cash', 'tinkoff_cash') then event_count end) as credit_cash_full_renders,
        sum(case when eventtype_ext = 4502 and x_from_page in ('sravni_cash', 'tinkoff_cash') then event_count end) as credit_cash_full_requests
    from credit_broker t
    group by cookie_id, cookie_id
) _
;

create metrics credit_broker as
select
    sum(case when event_name_slug = 'broker_credit_approved' and (x_from_page is null or x_from_page in ('landing_tinkoff', 'tinkoff')) then 1 end) as credit_auto_full_approvals,
    sum(case when eventtype_ext = 4498 and (x_from_page is null or x_from_page in ('landing_tinkoff', 'tinkoff')) then event_count end) as credit_auto_full_clicks,
    sum(case when is_early_closed = 1 and (x_from_page is null or x_from_page in ('landing_tinkoff', 'tinkoff')) then 1 end) as credit_auto_full_early_close,
    sum(case when eventtype_ext = 4590 and (x_from_page is null or x_from_page in ('landing_tinkoff', 'tinkoff')) then event_count end) as credit_auto_full_fillings,
    sum(case when is_issued = 1 and (x_from_page is null or x_from_page in ('landing_tinkoff', 'tinkoff')) then 1 end) as credit_auto_full_issues,
    sum(case when eventtype_ext = 5283 and (x_from_page is null or x_from_page in ('landing_tinkoff', 'tinkoff')) then event_count end) as credit_auto_full_loads,
    sum(case when eventtype_ext = 4801 and (x_from_page is null or x_from_page in ('landing_tinkoff', 'tinkoff')) then event_count end) as credit_auto_full_logo_clicks,
    sum(case when eventtype_ext = 4496 and (x_from_page is null or x_from_page in ('landing_tinkoff', 'tinkoff')) then event_count end) as credit_auto_full_renders,
    sum(case when eventtype_ext = 4502 and (x_from_page is null or x_from_page in ('landing_tinkoff', 'tinkoff')) then event_count end) as credit_auto_full_requests,
    sum(case when is_issued = 1 and is_early_closed is null and (x_from_page is null or x_from_page in ('landing_tinkoff', 'tinkoff')) then revenue end) as credit_auto_revenue,
    sum(case when event_name_slug = 'broker_credit_approved' and x_from_page in ('sravni_cash', 'tinkoff_cash') then 1 end) as credit_cash_full_approvals,
    sum(case when eventtype_ext = 4498 and x_from_page in ('sravni_cash', 'tinkoff_cash') then event_count end) as credit_cash_full_clicks,
    sum(case when is_early_closed = 1 and x_from_page in ('sravni_cash', 'tinkoff_cash') then 1 end) as credit_cash_full_early_close,
    sum(case when eventtype_ext = 4590 and x_from_page in ('sravni_cash', 'tinkoff_cash') then event_count end) as credit_cash_full_fillings,
    sum(case when is_issued = 1 and x_from_page in ('sravni_cash', 'tinkoff_cash') then 1 end) as credit_cash_full_issues,
    sum(case when eventtype_ext = 5283 and x_from_page in ('sravni_cash', 'tinkoff_cash') then event_count end) as credit_cash_full_loads,
    sum(case when eventtype_ext = 4801 and x_from_page in ('sravni_cash', 'tinkoff_cash') then event_count end) as credit_cash_full_logo_clicks,
    sum(case when eventtype_ext = 4496 and x_from_page in ('sravni_cash', 'tinkoff_cash') then event_count end) as credit_cash_full_renders,
    sum(case when eventtype_ext = 4502 and x_from_page in ('sravni_cash', 'tinkoff_cash') then event_count end) as credit_cash_full_requests,
    sum(case when is_issued = 1 and is_early_closed is null and x_from_page in ('sravni_cash', 'tinkoff_cash') then revenue end) as credit_cash_revenue
from credit_broker t
;
