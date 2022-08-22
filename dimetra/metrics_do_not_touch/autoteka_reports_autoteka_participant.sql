create fact autoteka_reports_autoteka_participant as
select
    t.autoteka_package_history_created_at::date as __date__,
    *
from dma.v_autoteka_reports t
;

create metrics autoteka_reports_autoteka_participant as
select
    sum(banner_clicks) as autoteka_banner_clicks_ap,
    sum(1) as autoteka_package_history_ap,
    sum(revenue_reports_used) as autoteka_revenue_reports_used_ap,
    sum(1) as autoteka_user_ap,
    sum(case when banner_clicks > 0 then 1 end) as autoteka_user_banner_clicks_ap,
    sum(1) as autoteka_vin_ap
from autoteka_reports_autoteka_participant t
;

create metrics autoteka_reports_autoteka_participant_autoteka_package_history_id as
select
    sum(case when autoteka_package_history_ap > 0 then 1 end) as autoteka_package_history_cnt_ap
from (
    select
        autoteka_cookie_id, autoteka_package_history_id,
        sum(1) as autoteka_package_history_ap
    from autoteka_reports_autoteka_participant t
    group by autoteka_cookie_id, autoteka_package_history_id
) _
;

create metrics autoteka_reports_autoteka_participant_autoteka_user_id as
select
    sum(case when autoteka_user_banner_clicks_ap > 0 then 1 end) as autoteka_user_banner_clicks_cnt_ap,
    sum(case when autoteka_user_ap > 0 then 1 end) as autoteka_user_cnt_ap
from (
    select
        autoteka_cookie_id, autoteka_user_id,
        sum(1) as autoteka_user_ap,
        sum(case when banner_clicks > 0 then 1 end) as autoteka_user_banner_clicks_ap
    from autoteka_reports_autoteka_participant t
    group by autoteka_cookie_id, autoteka_user_id
) _
;

create metrics autoteka_reports_autoteka_participant_vin as
select
    sum(case when autoteka_vin_ap > 0 then 1 end) as autoteka_vin_cnt_ap
from (
    select
        autoteka_cookie_id, vin,
        sum(1) as autoteka_vin_ap
    from autoteka_reports_autoteka_participant t
    group by autoteka_cookie_id, vin
) _
;
