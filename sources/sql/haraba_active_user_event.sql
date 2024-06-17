select 
    event_date
    ,coalesce(platform_name, 'web') as platform
    ,app_version
    ,haraba_user_id
    ,count(1) as events
from dma.haraba_events
where event_date between :first_date and :last_date
      and haraba_user_id is not null
      -- and event_month between date_trunc('month', :first_date) ) and date_trunc('month', :last_date) -- @trino
group by     
    event_date
    ,coalesce(platform_name, 'web')
    ,app_version
    ,haraba_user_id