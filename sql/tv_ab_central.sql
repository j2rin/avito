create or replace view saef.tv_ab_central as 
select
    r.ab_test_id,
    t.ab_test_ext_id,
    t.ab_test_label,
    t.ab_test_title,
    t.ab_test_description,
    t.salt,
    t.split_attribute as participant_type,
    t.status,
    t.team,
    t.start_time as ab_test_start_time,
    t.traffic_percent,
    
    r.period_id,
    p.period,
    p.start_time as period_start_time,
    p.end_time as period_end_time,
    
    r.metric_id,
    r.metric,
    
    p.start_time::date as start_date,
    r.calc_date,
    
    r.split_group_id,
    sg.split_group,
    sg.is_control,
    sg.split_lower_bound,
    sg.split_upper_bound,
    
    r.control_split_group_id,
    sgc.split_group as control_split_group,
    r.breakdown_hash,
    r.breakdown,
    r.class_name,
    r.method,
    r.stat_func,
    r.comp_func,
    r.null_value,
    r.alternative,
    r.alpha,
    r.is_pivotal,
    r.n_iters,
    r.mean,
    r.std,
    r.n_obs,
    r.p_value,
    r.test_statistic,
    r.lower_bound,
    r.upper_bound,
    r.elapsed_seconds,
    r.insert_datetime,
    r.cell_hash,
    r.slot_hash,
    r.params_hash,
    r.iter_hash,
    row_number() over(partition by cell_hash order by r.calc_date desc) as cell_day_rn_desc
from (
    select  r.*,
            hash(slot_hash, params_hash) as cell_hash,
            rank() over(partition by slot_hash, params_hash order by r.is_pivotal desc, r.n_iters desc) as secondary_params_rnk
    from (
        select  *,
                hash(r.ab_test_id, r.period_id, r.metric_id, r.metric, r.split_group_id, r.control_split_group_id, r.breakdown_hash) as slot_hash,
                hash(r.class_name, r.method, r.stat_func, r.comp_func, r.null_value, r.alternative, r.alpha) params_hash
        from    saef.ab_result r
    ) r
) r
join    dma.v_ab_test           t   on t.ab_test_id = r.ab_test_id
join    dma.v_ab_period         p   on p.ab_period_id = r.period_id
join    dma.v_ab_split_group    sg  on sg.ab_split_group_id = r.split_group_id
left join dma.v_ab_split_group  sgc on sgc.ab_split_group_id = r.control_split_group_id
where   secondary_params_rnk = 1
;

alter view saef.tv_ab_central owner to dbadmin;    
    
create table saef.ab_result_2 like saef.ab_result including projections;

insert /*+direct*/ into saef.ab_result_2
select  iter_hash,
        ab_test_id,
        period_id,
        metric_id,
        metric,
        calc_date,
        split_group_id,
        control_split_group_id,
        breakdown_hash,
        breakdown,
        class_name,
        method,
        stat_func,
        comp_func,
        null_value,
        alternative,
        alpha,
        is_pivotal,
        n_iters,
        mean,
        std,
        sum,
        n_obs,
        p_value,
        test_statistic,
        lower_bound,
        upper_bound,
        elapsed_seconds,
        insert_datetime
from (
    select  *,
            row_number() over(partition by iter_hash order by elapsed_seconds desc) as rn
    from    saef.ab_result
) ab
where rn = 1
;

drop table saef.ab_result cascade;
alter table saef.ab_result_2 rename to ab_result;

select  *
from    saef.ab_result

select  *, column_name || ',' as c
from    v_catalog.columns
where   table_name = 'ab_result'
;

select  *
from (
    select  *, count(*) over(partition by iter_hash) as cnt
    from    saef.ab_result
) r
where   cnt > 1



select  t.ab_test_id,
        m.ab_metric_id as metric_id,
        m.ab_metric_name as metric
from    dma.v_ab_test           t
join    dma.v_ab_test_metric    m   on  m.ab_test_id = t.ab_test_id
where   t.is_active
    and m.ab_test_metric_link_is_active
    and m.ab_metric_is_active
    and t.status in ('Ready for DWH', 'In progress', 'Interrupted', 'Ended')
    and t.ab_test_id = 532250001
;

select  *
from    dma.v_ab_test_metric
where   ab_test_id = 532250001






WITH
S_ABTest_IsActive                  AS (SELECT ABTest_id, IsActive                  FROM (SELECT ABTest_id, IsActive,                  ROW_NUMBER() OVER(PARTITION BY ABTest_id                  ORDER BY actual_date DESC) AS rnk FROM DDS.S_ABTest_IsActive) t                  WHERE rnk=1),
----
S_ABTestMetricLink_IsActive        AS (SELECT ABTestMetricLink_id, IsActive        FROM (SELECT ABTestMetricLink_id, IsActive,        ROW_NUMBER() OVER(PARTITION BY ABTestMetricLink_id        ORDER BY actual_date DESC) AS rnk FROM DDS.S_ABTestMetricLink_IsActive) t        WHERE rnk=1),
S_ABMetric_Title                   AS (SELECT ABMetric_id, Title                   FROM (SELECT ABMetric_id, Title,                   ROW_NUMBER() OVER(PARTITION BY ABMetric_id                ORDER BY actual_date DESC) AS rnk FROM DDS.S_ABMetric_Title) t                   WHERE rnk=1),
S_ABMetric_Description             AS (SELECT ABMetric_id, Description             FROM (SELECT ABMetric_id, Description,             ROW_NUMBER() OVER(PARTITION BY ABMetric_id                ORDER BY actual_date DESC) AS rnk FROM DDS.S_ABMetric_Description) t             WHERE rnk=1),
S_ABMetric_IsActive                AS (SELECT ABMetric_id, IsActive                FROM (SELECT ABMetric_id, IsActive,                ROW_NUMBER() OVER(PARTITION BY ABMetric_id                ORDER BY actual_date DESC) AS rnk FROM DDS.S_ABMetric_IsActive) t                WHERE rnk=1)
SELECT ht.ABTest_id          AS ab_test_id,
       tia.IsActive          AS ab_test_is_active,
       tct.CreateTime        AS ab_test_create_time,
       ----
       tmlm.ABMetric_id      AS ab_metric_id,
       tmlia.IsActive        AS ab_test_metric_link_is_active,
       m.External_id         AS ab_metric_name,
       mt.Title              AS ab_metric_title,
       md.Description        AS ab_metric_description,
       mia.IsActive          AS ab_metric_is_active,
       tmlt.ABTestMetricLink_id
  FROM      DDS.H_ABTest                                ht
  LEFT JOIN S_ABTest_IsActive                           tia   ON ht.ABTest_id = tia.ABTest_id
  LEFT JOIN DDS.S_ABTest_CreateTime                     tct   ON ht.ABTest_id = tct.ABTest_id
  ----
  INNER JOIN DDS.L_ABTestMetricLink_ABTest              tmlt  ON ht.ABTest_id = tmlt.ABTest_id
  LEFT JOIN DDS.L_ABTestMetricLink_ABMetric             tmlm  ON tmlt.ABTestMetricLink_id = tmlm.ABTestMetricLink_id
  LEFT JOIN S_ABTestMetricLink_IsActive                 tmlia ON tmlt.ABTestMetricLink_id = tmlia.ABTestMetricLink_id
  LEFT JOIN DDS.H_ABMetric                              m     ON tmlm.ABMetric_id = m.ABMetric_id
  LEFT JOIN S_ABMetric_Title                            mt    ON tmlm.ABMetric_id = mt.ABMetric_id
  LEFT JOIN S_ABMetric_Description                      md    ON tmlm.ABMetric_id = md.ABMetric_id
  LEFT JOIN S_ABMetric_IsActive                         mia   ON tmlm.ABMetric_id = mia.ABMetric_id
  where ht.abtest_id = 532250001
  
select  *
from    DDS.S_ABTest_CreateTime
where   abtest_id = 532250001
;

select  *
from    DDS.L_ABTestMetricLink_ABMetric 
where   AbMetric_id = 655000004

select  *
from    DDS.L_ABTestMetricLink_ABTest

  with
  S_ABTestMetricLink_IsActive        AS (SELECT ABTestMetricLink_id, IsActive        FROM (SELECT ABTestMetricLink_id, IsActive,        ROW_NUMBER() OVER(PARTITION BY ABTestMetricLink_id        ORDER BY actual_date DESC) AS rnk FROM DDS.S_ABTestMetricLink_IsActive) t        WHERE rnk=1)
  select    *
  from  DDS.L_ABTestMetricLink_ABTest              tmlt
  JOIN DDS.L_ABTestMetricLink_ABMetric             tmlm  ON tmlt.ABTestMetricLink_id = tmlm.ABTestMetricLink_id
  JOIN S_ABTestMetricLink_IsActive                 tmlia ON tmlt.ABTestMetricLink_id = tmlia.ABTestMetricLink_id
  join  DDS.H_ABTestMetricLink                     ml    on ml.ABTestMetricLink_id = tmlt.ABTestMetricLink_id
  where ABTest_id = 532250001
    and AbMetric_id = 655000004

where   