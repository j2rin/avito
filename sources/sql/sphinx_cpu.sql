SELECT
   	event_date,
    cookie_id,
    user_id,
    platform_id,
    context as sphinx_context,
    events_count,
    cputime_sum,
    less_25_perc_count,
    less_50_perc_count,
    less_75_perc_count,
    less_95_perc_count,
    x_count,
    over_sec_count
FROM dma.perf_sphinx_cputime_cleared
where event_date::date between :first_date and :last_date
