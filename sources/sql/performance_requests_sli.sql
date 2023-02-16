select event_date, platform_id, cookie_id, user_id, useragent_id, url_mask, success_requests, failed_requests
from dma.performance_requests_sli s
where event_date::date between :first_date and :last_date
