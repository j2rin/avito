create fact verified_users as
select
    t.event_time::date as __date__,
    *
from dma.verification_statuses t
;

create metrics verified_users as
select
    sum(case when verification_type = 'driver_license' and status = True then 1 end) as driver_license_verifications_success,
    sum(case when verification_type = 'INN' and status = True then 1 end) as inn_verifications_success,
    sum(case when verification_type = 'passport' and status = True then 1 end) as passport_verifications_success
from verified_users t
;

create metrics verified_users_user as
select
    sum(case when driver_license_verifications_success > 0 then 1 end) as driver_license_verified_users,
    sum(case when inn_verifications_success > 0 then 1 end) as inn_verified_users,
    sum(case when passport_verifications_success > 0 then 1 end) as passport_verified_users
from (
    select
        user_id,
        sum(case when verification_type = 'driver_license' and status = True then 1 end) as driver_license_verifications_success,
        sum(case when verification_type = 'INN' and status = True then 1 end) as inn_verifications_success,
        sum(case when verification_type = 'passport' and status = True then 1 end) as passport_verifications_success
    from verified_users t
    group by user_id
) _
;
