SELECT  
    observation_date AS event_date, 
    eid, 
    platform_id, 
    user_id, 
    cookie_id, 
    notification_channel, 
    notification_owner, 
    notification_type, 
    notification_value, 
    is_notifications_on, 
    events_count
FROM dma.notifications_metric_observation_new d
where observation_date::date between :first_date and :last_date
