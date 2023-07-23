SELECT
    event_date,
    event_datetime,
    user_id,
    passport_id,
    cookie_id,
    eid,
    business_platform AS platform_id,
    user_path,
    is_success,
    error_text
FROM dma.passport_event_stream
WHERE event_date BETWEEN :first_date AND :last_date
