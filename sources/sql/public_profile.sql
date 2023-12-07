   select observation_date as event_date,	
   		  platform_id,
   		  participant_id as cookie_id,
   		  contacts_public_profile,
    	  public_profile_views,
    	  public_profile_unique_views,
    	  public_profile_active_items_paginations,
    	  public_profile_closed_tabs,
    	  public_profile_closed_items_paginations 
    from dma.public_profile_metric_observation
where cast(observation_date as date) between :first_date and :last_date
    -- and observation_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
