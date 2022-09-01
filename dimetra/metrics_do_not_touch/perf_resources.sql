create fact perf_resources as
select
    t.event_date::date as __date__,
    *
from dma.performance_resources_web t
;

create metrics perf_resources as
select
    sum(case when resource_type = 'beacon' and location = 'external' then value end) as perf_resource_beacon_external_sum,
    sum(case when resource_type = 'beacon' and location = 'internal' then value end) as perf_resource_beacon_internal_sum,
    sum(case when resource_type = 'css' and location = 'external' then value end) as perf_resource_css_external_sum,
    sum(case when resource_type = 'css' and location = 'internal' then value end) as perf_resource_css_internal_sum,
    sum(case when resource_type = 'events' then value end) as perf_resource_events,
    sum(case when resource_type = 'fetch' and location = 'external' then value end) as perf_resource_fetch_external_sum,
    sum(case when resource_type = 'fetch' and location = 'internal' then value end) as perf_resource_fetch_internal_sum,
    sum(case when resource_type = 'iframe' and location = 'external' then value end) as perf_resource_iframe_external_sum,
    sum(case when resource_type = 'iframe' and location = 'internal' then value end) as perf_resource_iframe_internal_sum,
    sum(case when resource_type = 'img' and location = 'external' then value end) as perf_resource_img_external_sum,
    sum(case when resource_type = 'img' and location = 'internal' then value end) as perf_resource_img_internal_sum,
    sum(case when resource_type = 'link' and location = 'external' then value end) as perf_resource_link_external_sum,
    sum(case when resource_type = 'link' and location = 'internal' then value end) as perf_resource_link_internal_sum,
    sum(case when resource_type = 'other' and location = 'external' then value end) as perf_resource_other_external_sum,
    sum(case when resource_type = 'other' and location = 'internal' then value end) as perf_resource_other_internal_sum,
    sum(case when resource_type = 'script' and location = 'external' then value end) as perf_resource_script_external_sum,
    sum(case when resource_type = 'script' and location = 'internal' then value end) as perf_resource_script_internal_sum,
    sum(case when resource_type = 'xmlhttprequest' and location = 'external' then value end) as perf_resource_xmlhttprequest_external_sum,
    sum(case when resource_type = 'xmlhttprequest' and location = 'internal' then value end) as perf_resource_xmlhttprequest_internal_sum
from perf_resources t
;
