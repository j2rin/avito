create fact autoteka_stream_autoteka_participant as
select
    t.event_date::date as __date__,
    t.additionalcookie_id,
    t.amount,
    t.autoteka_cookie_id,
    t.autotekaorder_id,
    t.autotekauser_id,
    t.event_date,
    t.funnel_stage_id,
    t.is_new_user,
    t.is_pro,
    t.payment_method,
    t.reports_count
from dma.autoteka_stream t
;

create metrics autoteka_stream_autoteka_participant_autotekauser_id as
select
    sum(case when autoteka_cnt_big_package_ap > 0 then 1 end) as autoteka_big_package_buyer_ap,
    sum(case when autoteka_cnt_one_report_ap > 0 then 1 end) as autoteka_one_report_buyer_ap,
    sum(case when autoteka_cnt_small_package_ap > 0 then 1 end) as autoteka_small_package_buyer_ap,
    sum(case when autoteka_cnt_paypage_loads_ap > 0 then 1 end) as autoteka_unique_paypage_visitors_ap,
    sum(case when autoteka_cnt_reports_ap > 0 then 1 end) as autoteka_unique_report_buyers_ap,
    sum(case when autoteka_cnt_reports_new_users_ap > 0 then 1 end) as autoteka_unique_report_new_buyers_ap,
    sum(case when autoteka_cnt_reports_nonpro_users_ap > 0 then 1 end) as autoteka_unique_report_nonpro_buyers_ap,
    sum(case when autoteka_cnt_reports_pro_users_ap > 0 then 1 end) as autoteka_unique_report_pro_buyers_ap
from (
    select
        autoteka_cookie_id, autotekauser_id,
        sum(case when funnel_stage_id = 4 and reports_count >= 20 then reports_count end) as autoteka_cnt_big_package_ap,
        sum(case when funnel_stage_id = 4 and reports_count = 1 then reports_count end) as autoteka_cnt_one_report_ap,
        sum(case when funnel_stage_id = 3 then 1 end) as autoteka_cnt_paypage_loads_ap,
        sum(case when funnel_stage_id = 4 then reports_count end) as autoteka_cnt_reports_ap,
        sum(case when funnel_stage_id = 4 and is_new_user = True then reports_count end) as autoteka_cnt_reports_new_users_ap,
        sum(case when funnel_stage_id = 4 and is_pro = False then reports_count end) as autoteka_cnt_reports_nonpro_users_ap,
        sum(case when funnel_stage_id = 4 and is_pro = True then reports_count end) as autoteka_cnt_reports_pro_users_ap,
        sum(case when funnel_stage_id = 4 and reports_count > 1 and reports_count < 20 then reports_count end) as autoteka_cnt_small_package_ap
    from autoteka_stream_autoteka_participant t
    group by autoteka_cookie_id, autotekauser_id
) _
;

create metrics autoteka_stream_autoteka_participant_autotekaorder_id as
select
    sum(case when autoteka_cnt_big_package_ap > 0 then 1 end) as autoteka_big_package_purchase_ap,
    sum(case when autoteka_cnt_one_report_ap > 0 then 1 end) as autoteka_one_report_purchase_ap,
    sum(case when autoteka_cnt_apple_in_app_ap > 0 then 1 end) as autoteka_payment_apple_in_app_ap,
    sum(case when autoteka_cnt_apple_pay_ap > 0 then 1 end) as autoteka_payment_apple_pay_ap,
    sum(case when autoteka_cnt_card_ap > 0 then 1 end) as autoteka_payment_card_ap,
    sum(case when autoteka_cnt_gpay_ap > 0 then 1 end) as autoteka_payment_gpay_ap,
    sum(case when autoteka_cnt_sms_ap > 0 then 1 end) as autoteka_payment_sms_ap,
    sum(case when autoteka_cnt_small_package_ap > 0 then 1 end) as autoteka_small_package_purchase_ap
from (
    select
        autoteka_cookie_id, autotekaorder_id,
        sum(case when funnel_stage_id = 4 and payment_method = 'appleInAppPurchase' then 1 end) as autoteka_cnt_apple_in_app_ap,
        sum(case when funnel_stage_id = 4 and payment_method = 'applePay' then 1 end) as autoteka_cnt_apple_pay_ap,
        sum(case when funnel_stage_id = 4 and reports_count >= 20 then reports_count end) as autoteka_cnt_big_package_ap,
        sum(case when funnel_stage_id = 4 and payment_method = 'card' then 1 end) as autoteka_cnt_card_ap,
        sum(case when funnel_stage_id = 4 and payment_method = 'googlePay' then 1 end) as autoteka_cnt_gpay_ap,
        sum(case when funnel_stage_id = 4 and reports_count = 1 then reports_count end) as autoteka_cnt_one_report_ap,
        sum(case when funnel_stage_id = 4 and reports_count > 1 and reports_count < 20 then reports_count end) as autoteka_cnt_small_package_ap,
        sum(case when funnel_stage_id = 4 and payment_method = 'sms' then 1 end) as autoteka_cnt_sms_ap
    from autoteka_stream_autoteka_participant t
    group by autoteka_cookie_id, autotekaorder_id
) _
;

create metrics autoteka_stream_autoteka_participant as
select
    sum(case when funnel_stage_id = 4 and payment_method = 'appleInAppPurchase' then 1 end) as autoteka_cnt_apple_in_app_ap,
    sum(case when funnel_stage_id = 4 and payment_method = 'applePay' then 1 end) as autoteka_cnt_apple_pay_ap,
    sum(case when funnel_stage_id = 4 and reports_count >= 20 then reports_count end) as autoteka_cnt_big_package_ap,
    sum(case when funnel_stage_id = 4 and payment_method = 'card' then 1 end) as autoteka_cnt_card_ap,
    sum(case when funnel_stage_id = 4 and payment_method = 'googlePay' then 1 end) as autoteka_cnt_gpay_ap,
    sum(case when funnel_stage_id = 0 then 1 end) as autoteka_cnt_main_page_ap,
    sum(case when funnel_stage_id = 4 and reports_count = 1 then reports_count end) as autoteka_cnt_one_report_ap,
    sum(case when funnel_stage_id = 3 then 1 end) as autoteka_cnt_paypage_loads_ap,
    sum(case when funnel_stage_id = 1 then 1 end) as autoteka_cnt_previews_ap,
    sum(case when funnel_stage_id = 2 then 1 end) as autoteka_cnt_product_selections_ap,
    sum(case when funnel_stage_id = 4 then reports_count end) as autoteka_cnt_reports_ap,
    sum(case when funnel_stage_id = 4 and is_new_user = True then reports_count end) as autoteka_cnt_reports_new_users_ap,
    sum(case when funnel_stage_id = 4 and is_pro = False then reports_count end) as autoteka_cnt_reports_nonpro_users_ap,
    sum(case when funnel_stage_id = 4 and is_pro = True then reports_count end) as autoteka_cnt_reports_pro_users_ap,
    sum(case when funnel_stage_id = 4 and reports_count > 1 and reports_count < 20 then reports_count end) as autoteka_cnt_small_package_ap,
    sum(case when funnel_stage_id = 4 and payment_method = 'sms' then 1 end) as autoteka_cnt_sms_ap,
    sum(case when funnel_stage_id = 4 then amount end) as autoteka_revenue_ap,
    sum(case when funnel_stage_id = 4 and is_new_user = True then amount end) as autoteka_revenue_new_users_ap,
    sum(case when funnel_stage_id = 4 and is_pro = False then amount end) as autoteka_revenue_nonpro_users_ap,
    sum(case when funnel_stage_id = 4 and is_pro = True then amount end) as autoteka_revenue_pro_users_ap
from autoteka_stream_autoteka_participant t
;

create metrics autoteka_stream_autoteka_participant_additionalcookie_id as
select
    sum(case when autoteka_cnt_main_page_ap > 0 then 1 end) as autoteka_unique_main_page_visitors_ap,
    sum(case when autoteka_cnt_previews_ap > 0 then 1 end) as autoteka_unique_preview_visitors_ap,
    sum(case when autoteka_cnt_product_selections_ap > 0 then 1 end) as autoteka_unique_product_selection_visitors_ap
from (
    select
        autoteka_cookie_id, additionalcookie_id,
        sum(case when funnel_stage_id = 0 then 1 end) as autoteka_cnt_main_page_ap,
        sum(case when funnel_stage_id = 1 then 1 end) as autoteka_cnt_previews_ap,
        sum(case when funnel_stage_id = 2 then 1 end) as autoteka_cnt_product_selections_ap
    from autoteka_stream_autoteka_participant t
    group by autoteka_cookie_id, additionalcookie_id
) _
;
