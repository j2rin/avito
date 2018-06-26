create or replace view saef.tv_ab_central as 
select
    r.*,
    t.ab_test_ext_id as ab_test_ext,
    t.ab_test_label,
    t.ab_test_title,
    t.ab_test_description,
    t.salt,
    t.split_attribute as participant_type,
    t.status,
    t.team,
    t.start_time as ab_test_start_time,
    t.traffic_percent,
    p.period,
    p.start_time as period_start_time,
    p.end_time as period_end_time,
    p.start_time::date as start_date,
    sg.split_group,
    sg.is_control,
    sg.split_lower_bound,
    sg.split_upper_bound,
    sgc.split_group as control_split_group,    
    row_number() over(partition by slot_class_method_alt_hash, filter_rn order by r.calc_date desc) as day_rn_desc
from (
    select  r.*,
            hash(slot_hash, class_method_alt_hash) as slot_class_method_alt_hash,
            hash(slot_hash, calc_date) as slot_date_hash,
            hash(slot_hash, class_method_alt_hash, calc_date) as slot_class_method_alt_date_hash,
            row_number() over(partition by slot_hash, class_method_alt_hash, calc_date order by insert_datetime desc, r.is_pivotal desc, r.n_iters desc) as filter_rn
    from (
        select  *,
                hash(r.ab_test_id, r.period_id, r.metric_id, r.metric, r.split_group_id, r.control_split_group_id, r.breakdown_hash) as slot_hash,
                hash(r.ab_test_id, r.period_id, r.metric_id, r.metric, r.split_group_id, r.breakdown_hash) as sg_slot_hash,
                hash(r.ab_test_id, r.period_id, r.metric_id, r.metric, coalesce(r.control_split_group_id, r.split_group_id), r.breakdown_hash) as csg_slot_hash,
                hash(class_name, method_kind, alternative) as class_method_alt_hash
        from (
            select  *,
                        case
                        when r.method like 't\_%' then 'T'
                        when r.method like 'z\_%' then 'Z'
                        when r.method like 'mann\_%' then 'MW'
                        when r.method like 'bootstrap\_%' then 'Bootstrap'
                        when r.method like 'permutation\_%' then 'Permutation'
                        when r.method like 'proportion\_%' then 'Proportion Exact'
                        else r.method
                        end as
                    significance_test,
                        case
                        when r.method like 'mann\_%' then 'MW'
                        when r.method like '%stats%' then r.method
                        when r.method like '%\_test' and r.class_name = 'compare_observations' then 'T/Z/BS/PRM'
                        else 'Other'
                        end as
                    method_kind
            from    saef.ab_result r
        ) r
    ) r
    where   method_kind <> 'Other'
) r
join    dma.v_ab_test           t   on t.ab_test_id = r.ab_test_id
join    dma.v_ab_period         p   on p.ab_period_id = r.period_id
join    dma.v_ab_split_group    sg  on sg.ab_split_group_id = r.split_group_id
left join dma.v_ab_split_group  sgc on sgc.ab_split_group_id = r.control_split_group_id
where   filter_rn = 1
;

alter view saef.tv_ab_central owner to dbadmin;


--create table saef.ab_result_2 like saef.ab_result including projections;

