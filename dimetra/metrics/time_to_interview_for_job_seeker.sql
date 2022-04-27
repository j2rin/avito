create fact time_to_interview_for_job_seeker as
select
    t.cohort,
    t.event_time,
    t.job_seeker_user_id,
    t.time_to_acceptance,
    t.time_to_interview,
    t.job_seeker_user_id as user
from dma.vo_time_to_interview t
;

create metrics time_to_interview_for_job_seeker as
select
    sum(case when cohort = 'acceptance' and time_to_acceptance <= 2 and time_to_acceptance > 1 then 1 end) as acceptance_1_2_day_job_seeker,
    sum(case when cohort = 'acceptance' and time_to_acceptance <= 5 and time_to_acceptance > 2 then 1 end) as acceptance_2_5_day_job_seeker,
    sum(case when cohort = 'acceptance' and time_to_acceptance <= 10 and time_to_acceptance > 5 then 1 end) as acceptance_5_10_day_job_seeker,
    sum(case when cohort = 'acceptance' and time_to_acceptance <= 1 then 1 end) as acceptance_less_1_day_job_seeker,
    sum(case when cohort = 'acceptance' and time_to_acceptance > 10 then 1 end) as acceptance_more_than_10_day_job_seeker,
    sum(case when cohort = 'survey' then 1 end) as cnt_survey,
    sum(case when cohort = 'survey' and time_to_interview <= 10 then 1 end) as cnt_survey_less_10_day,
    sum(case when cohort = 'survey' and time_to_interview <= 1 then 1 end) as cnt_survey_less_1_day,
    sum(case when cohort = 'survey' and time_to_interview <= 2 then 1 end) as cnt_survey_less_2_day,
    sum(case when cohort = 'survey' and time_to_interview <= 5 then 1 end) as cnt_survey_less_5_day,
    sum(case when cohort = 'survey' and time_to_interview > 10 then 1 end) as cnt_survey_more_10_day,
    sum(case when cohort = 'interview' and time_to_interview <= 2 and time_to_interview > 1 then 1 end) as interview_1_2_day_job_seeker,
    sum(case when cohort = 'interview' and time_to_interview <= 5 and time_to_interview > 2 then 1 end) as interview_2_5_day_job_seeker,
    sum(case when cohort = 'interview' and time_to_interview <= 10 and time_to_interview > 5 then 1 end) as interview_5_10_day_job_seeker,
    sum(case when cohort = 'interview' and time_to_interview <= 1 then 1 end) as interview_less_1_day_job_seeker,
    sum(case when cohort = 'interview' and time_to_interview > 10 then 1 end) as interview_more_than_10_day_job_seeker
from time_to_interview_for_job_seeker t
;

create metrics time_to_interview_for_job_seeker_user as
select
    sum(case when cnt_survey > 0 then 1 end) as cnt_user_survey,
    sum(case when acceptance_1_2_day_job_seeker > 0 then 1 end) as job_seeker_with_acceptance_1_2_day,
    sum(case when acceptance_2_5_day_job_seeker > 0 then 1 end) as job_seeker_with_acceptance_2_5_day,
    sum(case when acceptance_5_10_day_job_seeker > 0 then 1 end) as job_seeker_with_acceptance_5_10_day,
    sum(case when acceptance_less_1_day_job_seeker > 0 then 1 end) as job_seeker_with_acceptance_less_1_day,
    sum(case when acceptance_more_than_10_day_job_seeker > 0 then 1 end) as job_seeker_with_acceptance_more_than_10_day,
    sum(case when interview_1_2_day_job_seeker > 0 then 1 end) as job_seeker_with_interview_1_2_day,
    sum(case when interview_2_5_day_job_seeker > 0 then 1 end) as job_seeker_with_interview_2_5_day,
    sum(case when interview_5_10_day_job_seeker > 0 then 1 end) as job_seeker_with_interview_5_10_day,
    sum(case when interview_less_1_day_job_seeker > 0 then 1 end) as job_seeker_with_interview_less_1_day,
    sum(case when interview_more_than_10_day_job_seeker > 0 then 1 end) as job_seeker_with_interview_more_than_10_day,
    sum(case when cnt_survey_less_10_day > 0 then 1 end) as user_survey_less_10_day,
    sum(case when cnt_survey_less_1_day > 0 then 1 end) as user_survey_less_1_day,
    sum(case when cnt_survey_less_2_day > 0 then 1 end) as user_survey_less_2_day,
    sum(case when cnt_survey_less_5_day > 0 then 1 end) as user_survey_less_5_day,
    sum(case when cnt_survey_more_10_day > 0 then 1 end) as user_survey_more_10_day
from (
    select
        job_seeker_user_id, user,
        sum(case when cohort = 'acceptance' and time_to_acceptance <= 2 and time_to_acceptance > 1 then 1 end) as acceptance_1_2_day_job_seeker,
        sum(case when cohort = 'acceptance' and time_to_acceptance <= 5 and time_to_acceptance > 2 then 1 end) as acceptance_2_5_day_job_seeker,
        sum(case when cohort = 'acceptance' and time_to_acceptance <= 10 and time_to_acceptance > 5 then 1 end) as acceptance_5_10_day_job_seeker,
        sum(case when cohort = 'acceptance' and time_to_acceptance <= 1 then 1 end) as acceptance_less_1_day_job_seeker,
        sum(case when cohort = 'acceptance' and time_to_acceptance > 10 then 1 end) as acceptance_more_than_10_day_job_seeker,
        sum(case when cohort = 'survey' then 1 end) as cnt_survey,
        sum(case when cohort = 'survey' and time_to_interview <= 10 then 1 end) as cnt_survey_less_10_day,
        sum(case when cohort = 'survey' and time_to_interview <= 1 then 1 end) as cnt_survey_less_1_day,
        sum(case when cohort = 'survey' and time_to_interview <= 2 then 1 end) as cnt_survey_less_2_day,
        sum(case when cohort = 'survey' and time_to_interview <= 5 then 1 end) as cnt_survey_less_5_day,
        sum(case when cohort = 'survey' and time_to_interview > 10 then 1 end) as cnt_survey_more_10_day,
        sum(case when cohort = 'interview' and time_to_interview <= 2 and time_to_interview > 1 then 1 end) as interview_1_2_day_job_seeker,
        sum(case when cohort = 'interview' and time_to_interview <= 5 and time_to_interview > 2 then 1 end) as interview_2_5_day_job_seeker,
        sum(case when cohort = 'interview' and time_to_interview <= 10 and time_to_interview > 5 then 1 end) as interview_5_10_day_job_seeker,
        sum(case when cohort = 'interview' and time_to_interview <= 1 then 1 end) as interview_less_1_day_job_seeker,
        sum(case when cohort = 'interview' and time_to_interview > 10 then 1 end) as interview_more_than_10_day_job_seeker
    from time_to_interview_for_job_seeker t
    group by job_seeker_user_id, user
) _
;
