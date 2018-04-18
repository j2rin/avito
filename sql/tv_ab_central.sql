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
    
    r.start_date,
    r.calc_date,
    
    r.split_group_id,
    sg.split_group,
    sg.is_control,
    sg.split_lower_bound,
    sg.split_upper_bound,
    
    r.control_split_group_id,
    sgc.split_group as control_split_group,
    
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
    row_number() over(partition by cell_hash order by r.calc_date desc) as cell_day_rn_desc
from (
    select  r.*,
            hash(slot_hash, params_hash) as cell_hash,
            rank() over(partition by slot_hash, params_hash order by r.is_pivotal desc, r.n_iters desc) as secondary_params_rnk
    from (
        select  *,
                hash(r.ab_test_id, r.period_id, r.metric_id, r.metric, r.start_date, r.split_group_id, r.control_split_group_id) as slot_hash,
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


select method, count(*) as cnt from saef.ab_result group by 1;

select * from saef.ab_result where insert_datetime is not null;

