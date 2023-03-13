select
    package_id,
    event_time,
    event_date,
    user_id,
    amount_net,
    metric_name,
    model,
    is_asd,
    is_first_purchase,
    is_recognized,
    has_trials,
    rn,
    is_listing,
    item_id,
    is_first_trial,
    platform_id,
    action_from
from dma.jobs_chatbot_metrics
where event_date::date between :first_date and :last_date
