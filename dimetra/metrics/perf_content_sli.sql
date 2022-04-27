create fact perf_content_sli as
select
    t.cookie_id,
    t.event_date,
    t.failed_requests,
    t.success_requests
from dma.performance_requests_sli t
;

create metrics perf_content_sli as
select
    sum(ifnull(failed_requests, 0) + ifnull(success_requests, 0)) as all_requests,
    sum(failed_requests) as failed_requests,
    sum(success_requests) as successful_requests
from perf_content_sli t
;