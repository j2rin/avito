select observation_date as event_date,
       platform_id,
       case when participant_type = 'visitor' then participant_id end as cookie_id,
       case when participant_type = 'user'    then participant_id end as user_id,
       participant_id,
       interaction_created,
       interaction_flow,
       interaction_automated,
       interaction_fully_automated,
       interaction_partly_automated,
       interaction_resolved,
       interaction_resolved_fcr,
       interaction_resolved_not_fcr,
       interaction_fcr_flow,
       interaction_ht,
       interaction_with_ht,
       interaction_csat,
       interaction_with_sat,
       interaction_ontime
from dma.support_crosschannel_metrics
where cast(observation_date as date) between :first_date and :last_date
    -- and observation_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
    
