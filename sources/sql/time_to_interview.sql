select 
	chat_id,
	job_seeker_user_id,
	job_employer_user_id,
	chat_item_id,
	cohort,
	case when cohort='invite' then event_date_invite 
    	when cohort='survey' then event_date_survey
        when cohort='interview' then chosen_interview_time 
        when cohort='activation' then chosen_interview_time
    	else event_date_acceptance end as event_time,
	case when cohort='invite' then platform_id_invite 
    	when cohort='survey' then platform_id_survey
        when cohort='interview' then platform_id_acceptance 
        when cohort='activation' then platform_id_acceptance
    	else platform_id_acceptance end as platform_id,    
	datediff('day', event_date_4066, event_date_invite) as time_to_invite_days,
    datediff('day', event_date_4066, event_date_survey) as time_to_survey_days, 
    datediff('day', event_date_4066, chosen_interview_time) as time_to_interview,
    datediff('day', item_activation_time, chosen_interview_time) as time_from_activation_to_interview,
    datediff('day', event_date_4066, event_date_acceptance) as time_to_acceptance
from dma.hiring_report dhr
cross join 
(
    select 'invite' as cohort 
    union all 
    select 'survey' as cohort 
    union all 
    select 'interview' as cohort 
    union all 
    select 'activation' as cohort 
    union all 
    select 'acceptance' as cohort 
)c
where event_time::date between :first_date and :last_date
