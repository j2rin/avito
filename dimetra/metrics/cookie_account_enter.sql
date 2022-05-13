create fact cookie_account_enter as
select
    t.event_date as __date__,
    t.auth_errors,
    t.auth_success,
    t.cookie_id as cookie,
    t.cookie_id,
    t.enter_errors,
    t.enter_start,
    t.enter_success,
    t.event_date,
    t.registration_errors,
    t.registration_success,
    t.restore_errors,
    t.restore_success
from dma.vo_cookie_account_enter t
;

create metrics cookie_account_enter as
select
    sum(ifnull(auth_errors, 0) + ifnull(auth_success, 0)) as auth_attempts,
    sum(auth_errors) as auth_errors,
    sum(auth_success) as auth_success,
    sum(enter_errors) as cnt_enter_errors,
    sum(ifnull(enter_errors, 0) + ifnull(enter_success, 0)) as cnt_enter_errors_success,
    sum(enter_success) as cnt_enter_success,
    sum(enter_start) as enter_start,
    sum(ifnull(restore_errors, 0) + ifnull(restore_success, 0)) as password_restore_attempts,
    sum(restore_errors) as password_restore_errors,
    sum(restore_success) as password_restore_success,
    sum(ifnull(registration_errors, 0) + ifnull(registration_success, 0)) as registration_attempts,
    sum(registration_errors) as registration_errors,
    sum(registration_success) as registration_success
from cookie_account_enter t
;

create metrics cookie_account_enter_cookie as
select
    sum(case when auth_success > 0 then 1 end) as user_auth,
    sum(case when auth_attempts > 0 then 1 end) as user_auth_attempt,
    sum(case when cnt_enter_success > 0 then 1 end) as user_enter,
    sum(case when cnt_enter_errors_success > 0 then 1 end) as user_enter_attempt,
    sum(case when enter_start > 0 then 1 end) as user_enter_start,
    sum(case when password_restore_success > 0 then 1 end) as user_password_restore,
    sum(case when password_restore_attempts > 0 then 1 end) as user_password_restore_attempt,
    sum(case when registration_success > 0 then 1 end) as user_registration,
    sum(case when registration_attempts > 0 then 1 end) as user_registration_attempt
from (
    select
        cookie_id, cookie,
        sum(ifnull(auth_errors, 0) + ifnull(auth_success, 0)) as auth_attempts,
        sum(auth_success) as auth_success,
        sum(ifnull(enter_errors, 0) + ifnull(enter_success, 0)) as cnt_enter_errors_success,
        sum(enter_success) as cnt_enter_success,
        sum(enter_start) as enter_start,
        sum(ifnull(restore_errors, 0) + ifnull(restore_success, 0)) as password_restore_attempts,
        sum(restore_success) as password_restore_success,
        sum(ifnull(registration_errors, 0) + ifnull(registration_success, 0)) as registration_attempts,
        sum(registration_success) as registration_success
    from cookie_account_enter t
    group by cookie_id, cookie
) _
;
