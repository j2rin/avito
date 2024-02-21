SELECT
    launch_id AS _,
    calc_date,
    hacked_avg,
    hacks_per_100k_auths
FROM dma.okr_hacked_metric
WHERE calc_date BETWEEN :first_date AND :last_date
-- AND calc_year between date_trunc('year', :first_date) AND date_trunc('year', :last_date) --@trino