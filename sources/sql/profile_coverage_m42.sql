SELECT
    launch_id AS _,
    event_date,
    MAX(CASE WHEN vertical = 'Any' THEN pro_users END) AS profile_coverage_abs,
    MAX(CASE WHEN vertical = 'Auto' THEN pro_users END) AS profile_coverage_abs_auto,
    MAX(CASE WHEN vertical = 'General' THEN pro_users END) AS profile_coverage_abs_goods,
    MAX(CASE WHEN vertical = 'Job' THEN pro_users END) AS profile_coverage_abs_jobs,
    MAX(CASE WHEN vertical = 'Realty' THEN pro_users END) AS profile_coverage_abs_realty,
    MAX(CASE WHEN vertical = 'Services' THEN pro_users END) AS profile_coverage_abs_services,
    MAX(CASE WHEN vertical = 'Any' THEN cast(pro_users/base*10000 as int) END) AS profile_coverage,
    MAX(CASE WHEN vertical = 'Auto' THEN cast(pro_users/base*10000 as int) END) AS profile_coverage_auto,
    MAX(CASE WHEN vertical = 'General' THEN cast(pro_users/base*10000 as int) END) AS profile_coverage_goods,
    MAX(CASE WHEN vertical = 'Job' THEN cast(pro_users/base*10000 as int) END) AS profile_coverage_jobs,
    MAX(CASE WHEN vertical = 'Realty' THEN cast(pro_users/base*10000 as int) END) AS profile_coverage_realty,
    MAX(CASE WHEN vertical = 'Services' THEN cast(pro_users/base*10000 as int) END) AS profile_coverage_services
FROM dma.profile_vertical_coverage
WHERE event_date BETWEEN :first_date AND :last_date
--and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
GROUP BY launch_id, event_date
