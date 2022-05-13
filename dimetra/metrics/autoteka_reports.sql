create fact autoteka_reports as
select
    t.autoteka_package_history_created_at::date as __date__,
    t.autoteka_package_history_created_at,
    t.autoteka_package_history_id,
    t.autoteka_user_id,
    t.banner_clicks,
    t.cookie_id,
    t.vin
from dma.v_autoteka_reports t
;

create metrics autoteka_reports as
select
    sum(banner_clicks) as autoteka_banner_clicks,
    sum(1) as autoteka_package_history,
    sum(1) as autoteka_user,
    sum(case when banner_clicks > 0 then 1 end) as autoteka_user_banner_clicks,
    sum(1) as autoteka_vin
from autoteka_reports t
;

create metrics autoteka_reports_autoteka_package_history_id as
select
    sum(case when autoteka_package_history > 0 then 1 end) as autoteka_package_history_cnt
from (
    select
        cookie_id, autoteka_package_history_id,
        sum(1) as autoteka_package_history
    from autoteka_reports t
    group by cookie_id, autoteka_package_history_id
) _
;

create metrics autoteka_reports_autoteka_user_id as
select
    sum(case when autoteka_user_banner_clicks > 0 then 1 end) as autoteka_user_banner_clicks_cnt,
    sum(case when autoteka_user > 0 then 1 end) as autoteka_user_cnt
from (
    select
        cookie_id, autoteka_user_id,
        sum(1) as autoteka_user,
        sum(case when banner_clicks > 0 then 1 end) as autoteka_user_banner_clicks
    from autoteka_reports t
    group by cookie_id, autoteka_user_id
) _
;

create metrics autoteka_reports_vin as
select
    sum(case when autoteka_vin > 0 then 1 end) as autoteka_vin_cnt
from (
    select
        cookie_id, vin,
        sum(1) as autoteka_vin
    from autoteka_reports t
    group by cookie_id, vin
) _
;
