create fact perf_queried_hosts_durations as
select
    t.event_date::date as __date__,
    *
from dma.perf_queried_hosts_durations t
;

create metrics perf_queried_hosts_durations as
select
    sum(duration_sum) as queried_hosts_durations_sum,
    sum(case when host = 'www.avito.ru' then duration_sum end) as queried_hosts_durations_sum_avito,
    sum(case when host = 'img.avito.st' then duration_sum end) as queried_hosts_durations_sum_img,
    sum(case when host = 'other' then duration_sum end) as queried_hosts_durations_sum_other,
    sum(case when host = 'stats.avito.ru' then duration_sum end) as queried_hosts_durations_sum_stats,
    sum(events_count) as queried_hosts_events,
    sum(case when host = 'www.avito.ru' then events_count end) as queried_hosts_events_avito,
    sum(case when host = 'img.avito.st' then events_count end) as queried_hosts_events_img,
    sum(case when host = 'other' then events_count end) as queried_hosts_events_other,
    sum(case when host = 'stats.avito.ru' then events_count end) as queried_hosts_events_stats
from perf_queried_hosts_durations t
;
