create fact autoteka_stream as
select
    t.event_date::date as __date__,
    *
from dma.autoteka_stream t
;

create metrics autoteka_stream_autotekauser_id as
select
    sum(case when autoteka_cnt_big_package > 0 then 1 end) as autoteka_big_package_buyer,
    sum(case when autoteka_cnt_one_report > 0 then 1 end) as autoteka_one_report_buyer,
    sum(case when autoteka_cnt_small_package > 0 then 1 end) as autoteka_small_package_buyer,
    sum(case when autoteka_cnt_paypage_loads > 0 then 1 end) as autoteka_unique_paypage_visitors,
    sum(case when autoteka_cnt_reports > 0 then 1 end) as autoteka_unique_report_buyers,
    sum(case when autoteka_cnt_reports_new_users > 0 then 1 end) as autoteka_unique_report_new_buyers,
    sum(case when autoteka_cnt_reports_nonpro_users > 0 then 1 end) as autoteka_unique_report_nonpro_buyers,
    sum(case when autoteka_cnt_reports_pro_users > 0 then 1 end) as autoteka_unique_report_pro_buyers
from (
    select
        cookie_id, autotekauser_id,
        sum(case when funnel_stage_id = 4 and reports_count >= 20 then reports_count end) as autoteka_cnt_big_package,
        sum(case when funnel_stage_id = 4 and reports_count = 1 then reports_count end) as autoteka_cnt_one_report,
        sum(case when funnel_stage_id = 3 then 1 end) as autoteka_cnt_paypage_loads,
        sum(case when funnel_stage_id = 4 then reports_count end) as autoteka_cnt_reports,
        sum(case when funnel_stage_id = 4 and is_new_user = True then reports_count end) as autoteka_cnt_reports_new_users,
        sum(case when funnel_stage_id = 4 and is_pro = False then reports_count end) as autoteka_cnt_reports_nonpro_users,
        sum(case when funnel_stage_id = 4 and is_pro = True then reports_count end) as autoteka_cnt_reports_pro_users,
        sum(case when funnel_stage_id = 4 and reports_count > 1 and reports_count < 20 then reports_count end) as autoteka_cnt_small_package
    from autoteka_stream t
    group by cookie_id, autotekauser_id
) _
;

create metrics autoteka_stream_autotekaorder_id as
select
    sum(case when autoteka_cnt_big_package > 0 then 1 end) as autoteka_big_package_purchase,
    sum(case when autoteka_cnt_one_report > 0 then 1 end) as autoteka_one_report_purchase,
    sum(case when autoteka_cnt_apple_in_app > 0 then 1 end) as autoteka_payment_apple_in_app,
    sum(case when autoteka_cnt_apple_pay > 0 then 1 end) as autoteka_payment_apple_pay,
    sum(case when autoteka_cnt_card > 0 then 1 end) as autoteka_payment_card,
    sum(case when autoteka_cnt_gpay > 0 then 1 end) as autoteka_payment_gpay,
    sum(case when autoteka_cnt_sms > 0 then 1 end) as autoteka_payment_sms,
    sum(case when autoteka_cnt_small_package > 0 then 1 end) as autoteka_small_package_purchase
from (
    select
        cookie_id, autotekaorder_id,
        sum(case when funnel_stage_id = 4 and payment_method = 'appleInAppPurchase' then 1 end) as autoteka_cnt_apple_in_app,
        sum(case when funnel_stage_id = 4 and payment_method = 'applePay' then 1 end) as autoteka_cnt_apple_pay,
        sum(case when funnel_stage_id = 4 and reports_count >= 20 then reports_count end) as autoteka_cnt_big_package,
        sum(case when funnel_stage_id = 4 and payment_method = 'card' then 1 end) as autoteka_cnt_card,
        sum(case when funnel_stage_id = 4 and payment_method = 'googlePay' then 1 end) as autoteka_cnt_gpay,
        sum(case when funnel_stage_id = 4 and reports_count = 1 then reports_count end) as autoteka_cnt_one_report,
        sum(case when funnel_stage_id = 4 and reports_count > 1 and reports_count < 20 then reports_count end) as autoteka_cnt_small_package,
        sum(case when funnel_stage_id = 4 and payment_method = 'sms' then 1 end) as autoteka_cnt_sms
    from autoteka_stream t
    group by cookie_id, autotekaorder_id
) _
;

create metrics autoteka_stream as
select
    sum(case when funnel_stage_id = 4 and payment_method = 'appleInAppPurchase' then 1 end) as autoteka_cnt_apple_in_app,
    sum(case when funnel_stage_id = 4 and payment_method = 'applePay' then 1 end) as autoteka_cnt_apple_pay,
    sum(case when funnel_stage_id = 4 and reports_count >= 20 then reports_count end) as autoteka_cnt_big_package,
    sum(case when funnel_stage_id = 4 and payment_method = 'card' then 1 end) as autoteka_cnt_card,
    sum(case when funnel_stage_id = 4 and payment_method = 'googlePay' then 1 end) as autoteka_cnt_gpay,
    sum(case when funnel_stage_id = 0 then 1 end) as autoteka_cnt_main_page,
    sum(case when funnel_stage_id = 4 and reports_count = 1 then reports_count end) as autoteka_cnt_one_report,
    sum(case when funnel_stage_id = 3 then 1 end) as autoteka_cnt_paypage_loads,
    sum(case when funnel_stage_id = 1 then 1 end) as autoteka_cnt_previews,
    sum(case when funnel_stage_id = 2 then 1 end) as autoteka_cnt_product_selections,
    sum(case when funnel_stage_id = 4 then reports_count end) as autoteka_cnt_reports,
    sum(case when funnel_stage_id = 4 and is_new_user = True then reports_count end) as autoteka_cnt_reports_new_users,
    sum(case when funnel_stage_id = 4 and is_pro = False then reports_count end) as autoteka_cnt_reports_nonpro_users,
    sum(case when funnel_stage_id = 4 and is_pro = True then reports_count end) as autoteka_cnt_reports_pro_users,
    sum(case when funnel_stage_id = 4 and reports_count > 1 and reports_count < 20 then reports_count end) as autoteka_cnt_small_package,
    sum(case when funnel_stage_id = 4 and payment_method = 'sms' then 1 end) as autoteka_cnt_sms,
    sum(case when funnel_stage_id = 4 then amount end) as autoteka_revenue,
    sum(case when funnel_stage_id = 4 and is_new_user = True then amount end) as autoteka_revenue_new_users,
    sum(case when funnel_stage_id = 4 and is_pro = False then amount end) as autoteka_revenue_nonpro_users,
    sum(case when funnel_stage_id = 4 and is_pro = True then amount end) as autoteka_revenue_pro_users
from autoteka_stream t
;

create metrics autoteka_stream_additionalcookie_id as
select
    sum(case when autoteka_cnt_main_page > 0 then 1 end) as autoteka_unique_main_page_visitors
from (
    select
        cookie_id, additionalcookie_id,
        sum(case when funnel_stage_id = 0 then 1 end) as autoteka_cnt_main_page
    from autoteka_stream t
    group by cookie_id, additionalcookie_id
) _
;

create metrics autoteka_stream_cookie_id as
select
    sum(case when autoteka_cnt_previews > 0 then 1 end) as autoteka_unique_preview_visitors,
    sum(case when autoteka_cnt_product_selections > 0 then 1 end) as autoteka_unique_product_selection_visitors
from (
    select
        cookie_id,
        sum(case when funnel_stage_id = 1 then 1 end) as autoteka_cnt_previews,
        sum(case when funnel_stage_id = 2 then 1 end) as autoteka_cnt_product_selections
    from autoteka_stream t
    group by cookie_id
) _
;
