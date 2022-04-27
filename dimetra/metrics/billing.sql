create fact billing as
select
    t.event_date,
    t.payment_method_choice,
    t.payment_method_choice_account_pay,
    t.payment_method_choice_cv,
    t.payment_method_choice_services,
    t.payment_method_choice_wallet,
    t.payment_method_page,
    t.payment_method_page_account_pay,
    t.payment_method_page_cv,
    t.payment_method_page_services,
    t.payment_method_page_wallet,
    t.services_amount,
    t.successful_payment,
    t.successful_payment_account_pay,
    t.successful_payment_card,
    t.successful_payment_cv,
    t.successful_payment_sbol,
    t.successful_payment_services,
    t.successful_payment_wallet,
    t.user_id as user,
    t.user_id
from dma.vo_billing t
;

create metrics billing as
select
    sum(ifnull(successful_payment_card, 0) + ifnull(successful_payment_sbol, 0)) as cnt_successful_payment_sbol_card,
    sum(payment_method_choice) as payment_method_choice,
    sum(payment_method_choice_account_pay) as payment_method_choice_account_pay,
    sum(payment_method_choice_cv) as payment_method_choice_cv,
    sum(payment_method_choice_services) as payment_method_choice_services,
    sum(payment_method_choice_wallet) as payment_method_choice_wallet,
    sum(payment_method_page) as payment_method_page,
    sum(payment_method_page_account_pay) as payment_method_page_account_pay,
    sum(payment_method_page_cv) as payment_method_page_cv,
    sum(payment_method_page_services) as payment_method_page_services,
    sum(payment_method_page_wallet) as payment_method_page_wallet,
    sum(successful_payment) as successful_payment,
    sum(successful_payment_account_pay) as successful_payment_account_pay,
    sum(successful_payment_cv) as successful_payment_cv,
    sum(successful_payment_services) as successful_payment_services,
    sum(services_amount) as successful_payment_services_amount,
    sum(successful_payment_wallet) as successful_payment_wallet
from billing t
;

create metrics billing_user as
select
    sum(case when payment_method_choice_cv > 0 then 1 end) as unq_payment_method_choice_cv,
    sum(case when payment_method_choice_services > 0 then 1 end) as unq_payment_method_choice_services,
    sum(case when payment_method_page_cv > 0 then 1 end) as unq_payment_method_page_cv,
    sum(case when payment_method_page_services > 0 then 1 end) as unq_payment_method_page_services,
    sum(case when successful_payment_cv > 0 then 1 end) as unq_successful_payment_cv,
    sum(case when successful_payment_services > 0 then 1 end) as unq_successful_payment_services,
    sum(case when payment_method_choice > 0 then 1 end) as user_payment_method_choice,
    sum(case when payment_method_choice_account_pay > 0 then 1 end) as user_payment_method_choice_account_pay,
    sum(case when payment_method_choice_wallet > 0 then 1 end) as user_payment_method_choice_wallet,
    sum(case when payment_method_page > 0 then 1 end) as user_payment_method_page,
    sum(case when payment_method_page_account_pay > 0 then 1 end) as user_payment_method_page_account_pay,
    sum(case when payment_method_page_wallet > 0 then 1 end) as user_payment_method_page_wallet,
    sum(case when successful_payment > 0 then 1 end) as user_successful_payment,
    sum(case when successful_payment_account_pay > 0 then 1 end) as user_successful_payment_account_pay,
    sum(case when successful_payment_wallet > 0 then 1 end) as user_successful_payment_wallet
from (
    select
        user_id, user,
        sum(payment_method_choice) as payment_method_choice,
        sum(payment_method_choice_account_pay) as payment_method_choice_account_pay,
        sum(payment_method_choice_cv) as payment_method_choice_cv,
        sum(payment_method_choice_services) as payment_method_choice_services,
        sum(payment_method_choice_wallet) as payment_method_choice_wallet,
        sum(payment_method_page) as payment_method_page,
        sum(payment_method_page_account_pay) as payment_method_page_account_pay,
        sum(payment_method_page_cv) as payment_method_page_cv,
        sum(payment_method_page_services) as payment_method_page_services,
        sum(payment_method_page_wallet) as payment_method_page_wallet,
        sum(successful_payment) as successful_payment,
        sum(successful_payment_account_pay) as successful_payment_account_pay,
        sum(successful_payment_cv) as successful_payment_cv,
        sum(successful_payment_services) as successful_payment_services,
        sum(successful_payment_wallet) as successful_payment_wallet
    from billing t
    group by user_id, user
) _
;
