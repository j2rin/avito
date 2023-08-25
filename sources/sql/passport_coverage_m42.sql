SELECT
    launch_id AS _,
    calc_date,
    weighted_coverage_multi
FROM dma.passport_coverage
WHERE calc_date BETWEEN :first_date AND :last_date
;