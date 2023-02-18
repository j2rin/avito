SELECT
    actual_date as event_date,
    user_id,
    isDeliveryActive
FROM DDS.S_User_isDeliveryActive
where event_date::date between :first_date and :last_date
