create fact sphinx_cputime as
select
    t.event_date::date as __date__,
    *
from dma.vo_sphinx_cpu t
;

create metrics sphinx_cputime as
select
    sum(x_count) as cnt_searches_sphinx,
    sum(cputime_sum) as cnt_sphinx_cputime,
    sum(less_25_perc_count) as cnt_sphinx_cputime_25_perc,
    sum(less_50_perc_count) as cnt_sphinx_cputime_50_perc,
    sum(less_75_perc_count) as cnt_sphinx_cputime_75_perc,
    sum(less_95_perc_count) as cnt_sphinx_cputime_95_perc,
    sum(events_count) as cnt_sphinx_cputime_events,
    sum(over_sec_count) as cnt_sphinx_cputime_over_sec
from sphinx_cputime t
;

create metrics sphinx_cputime_cookie as
select
    sum(case when cnt_sphinx_cputime_events > 0 then 1 end) as user_sphinx
from (
    select
        cookie_id,
        sum(events_count) as cnt_sphinx_cputime_events
    from sphinx_cputime t
    group by cookie_id
) _
;
