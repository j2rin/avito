create fact time_to_interview_for_job_employer as
select
    t.event_time::date as __date__,
    t.cohort,
    t.event_time,
    t.job_employer_user_id,
    t.time_from_activation_to_interview,
    t.time_to_invite_days,
    t.job_employer_user_id as user
from dma.vo_time_to_interview t
;

create metrics time_to_interview_for_job_employer as
select
    sum(case when cohort = 'activation' and time_from_activation_to_interview <= 48 and time_from_activation_to_interview > 24 then 1 end) as interview_1_2_day_after_activation,
    sum(case when cohort = 'activation' and time_from_activation_to_interview <= 120 and time_from_activation_to_interview > 48 then 1 end) as interview_2_5_day_after_activation,
    sum(case when cohort = 'activation' and time_from_activation_to_interview <= 240 and time_from_activation_to_interview > 120 then 1 end) as interview_5_10_day_after_activation,
    sum(case when cohort = 'activation' and time_from_activation_to_interview <= 24 then 1 end) as interview_less_1_day_after_activation,
    sum(case when cohort = 'activation' and time_from_activation_to_interview > 240 then 1 end) as interview_more_than_10_day_after_activation,
    sum(case when cohort = 'invite' and time_to_invite_days <= 48 and time_to_invite_days > 24 then 1 end) as invites_1_2_day_job_employer,
    sum(case when cohort = 'invite' and time_to_invite_days <= 120 and time_to_invite_days > 48 then 1 end) as invites_2_5_day_job_employer,
    sum(case when cohort = 'invite' and time_to_invite_days <= 240 and time_to_invite_days > 120 then 1 end) as invites_5_10_day_job_employer,
    sum(case when cohort = 'invite' and time_to_invite_days <= 24 then 1 end) as invites_less_1_day_job_employer,
    sum(case when cohort = 'invite' and time_to_invite_days > 240 then 1 end) as invites_more_than_10_day_job_employer
from time_to_interview_for_job_employer t
;

create metrics time_to_interview_for_job_employer_user as
select
    sum(case when invites_1_2_day_job_employer > 0 then 1 end) as job_employer_with_invite_1_2_day,
    sum(case when interview_1_2_day_after_activation > 0 then 1 end) as job_employer_with_invite_1_2_day_after_activation,
    sum(case when invites_2_5_day_job_employer > 0 then 1 end) as job_employer_with_invite_2_5_day,
    sum(case when interview_2_5_day_after_activation > 0 then 1 end) as job_employer_with_invite_2_5_day_after_activation,
    sum(case when invites_5_10_day_job_employer > 0 then 1 end) as job_employer_with_invite_5_10_day,
    sum(case when interview_5_10_day_after_activation > 0 then 1 end) as job_employer_with_invite_5_10_day_after_activation,
    sum(case when invites_less_1_day_job_employer > 0 then 1 end) as job_employer_with_invite_less_1_day,
    sum(case when interview_less_1_day_after_activation > 0 then 1 end) as job_employer_with_invite_less_1_day_after_activation,
    sum(case when invites_more_than_10_day_job_employer > 0 then 1 end) as job_employer_with_invite_more_than_10_day,
    sum(case when interview_more_than_10_day_after_activation > 0 then 1 end) as job_employer_with_invite_more_than_10_day_after_activation
from (
    select
        job_employer_user_id, user,
        sum(case when cohort = 'activation' and time_from_activation_to_interview <= 48 and time_from_activation_to_interview > 24 then 1 end) as interview_1_2_day_after_activation,
        sum(case when cohort = 'activation' and time_from_activation_to_interview <= 120 and time_from_activation_to_interview > 48 then 1 end) as interview_2_5_day_after_activation,
        sum(case when cohort = 'activation' and time_from_activation_to_interview <= 240 and time_from_activation_to_interview > 120 then 1 end) as interview_5_10_day_after_activation,
        sum(case when cohort = 'activation' and time_from_activation_to_interview <= 24 then 1 end) as interview_less_1_day_after_activation,
        sum(case when cohort = 'activation' and time_from_activation_to_interview > 240 then 1 end) as interview_more_than_10_day_after_activation,
        sum(case when cohort = 'invite' and time_to_invite_days <= 48 and time_to_invite_days > 24 then 1 end) as invites_1_2_day_job_employer,
        sum(case when cohort = 'invite' and time_to_invite_days <= 120 and time_to_invite_days > 48 then 1 end) as invites_2_5_day_job_employer,
        sum(case when cohort = 'invite' and time_to_invite_days <= 240 and time_to_invite_days > 120 then 1 end) as invites_5_10_day_job_employer,
        sum(case when cohort = 'invite' and time_to_invite_days <= 24 then 1 end) as invites_less_1_day_job_employer,
        sum(case when cohort = 'invite' and time_to_invite_days > 240 then 1 end) as invites_more_than_10_day_job_employer
    from time_to_interview_for_job_employer t
    group by job_employer_user_id, user
) _
;
