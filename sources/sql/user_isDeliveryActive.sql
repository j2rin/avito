SELECT
    actual_date as event_date,
    user_id,
    isDeliveryActive
FROM DDS.S_User_isDeliveryActive
where cast(actual_date as date) between :first_date and :last_date
