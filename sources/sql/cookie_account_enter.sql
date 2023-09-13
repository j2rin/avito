select
    event_date,
    cookie_id,
    platform_id,
    restore_platform_id,
    is_cookie_first_day,
    enter_start,
    auth_success,
    registration_start,
    registration_success,
    restore_start,
    restore_success,
    restore_platform_change,
    enter_success,
    auth_errors,
    registration_errors,
    restore_errors,
    enter_errors,
    social_start,
    reg_social_success,
    auth_social_success,
    auth_notsocial_success
from    dma.cookie_account_enter
where   enter_start > 0 or restore_start > 0
    and cast(event_date as date) between :first_date and :last_date
