SELECT
    launch_id AS _,
    event_date,
    MAX(CASE WHEN vertical = 'Any' THEN pro_users END) AS profile_coverage_abs,
    MAX(CASE WHEN vertical = 'Auto' THEN pro_users END) AS profile_coverage_abs_auto,
    MAX(CASE WHEN vertical = 'General' THEN pro_users END) AS profile_coverage_abs_goods,
    MAX(CASE WHEN vertical = 'Job' THEN pro_users END) AS profile_coverage_abs_jobs,
    MAX(CASE WHEN vertical = 'Realty' THEN pro_users END) AS profile_coverage_abs_realty,
    MAX(CASE WHEN vertical = 'Services' THEN pro_users END) AS profile_coveragex_abs_realty,
    MAX(CASE WHEN vertical = 'Any' THEN (pro_users/base*10000)::int END) AS profile_coverage,
    MAX(CASE WHEN vertical = 'Auto' THEN (pro_users/base*10000)::int END) AS profile_coverage_auto,
    MAX(CASE WHEN vertical = 'General' THEN (pro_users/base*10000)::int END) AS profile_coverage_goods,
    MAX(CASE WHEN vertical = 'Job' THEN (pro_users/base*10000)::int END) AS profile_coverage_jobs,
    MAX(CASE WHEN vertical = 'Realty' THEN (pro_users/base*10000)::int END) AS profile_coverage_realty,
    MAX(CASE WHEN vertical = 'Services' THEN (pro_users/base*10000)::int END) AS profile_coverage_services
FROM dma.profile_vertical_coverage
WHERE event_date BETWEEN :first_date AND :last_date
GROUP BY 1,2