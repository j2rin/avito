SELECT
    launch_id AS _,
    calc_date,
    weighted_coverage_multi * 10000 as weighted_coverage_multi
FROM dma.passport_coverage
WHERE calc_date BETWEEN :first_date AND :last_date
--AND calc_year between date_trunc('year', :first_date) AND date_trunc('year', :last_date) --@trino;