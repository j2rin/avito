create or replace view saef.tv_ab_central as 
select
    r.ab_test_id,
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
    r.slot_hash,
    r.params_hash,
    r.slot_sign_params_hash,
    r.slot_sign_test_hash,
    r.slot_date_hash,
    r.iter_hash,
    r.significance_test,
    r.method_kind,
    r.stat_val,
    r.std_stat_val,
    r.resampling,
    r.variance,
    row_number() over(partition by r.slot_sign_params_hash order by r.calc_date desc) as cell_day_rn_desc
from (
    select  r.*,
            hash(slot_hash, significance_test) as slot_sign_test_hash,
            hash(slot_hash, calc_date) as slot_date_hash,
            hash(slot_hash, params_hash) as slot_sign_params_hash,
            rank() over(partition by slot_hash, params_hash order by r.is_pivotal desc, r.n_iters desc) as secondary_params_rnk
    from (
        select  *,
                hash(r.ab_test_id, r.period_id, r.metric_id, r.metric, r.split_group_id, r.control_split_group_id, r.breakdown_hash) as slot_hash,
                hash(r.class_name, r.method, r.stat_func, r.comp_func, r.null_value, r.alternative, r.alpha) as params_hash,
                    case
                    when r.method like 't\_%' then 'T'
                    when r.method like 'z\_%' then 'Z'
                    when r.method like 'mann\_%' then 'MW U'
                    when r.method like 'bootstrap\_%' then 'Bootstrap'
                    when r.method like 'permutation\_%' then 'Permutation'
                    when r.method like 'proportion\_%' then 'Proportion Exact'
                    else r.method
                    end as
                significance_test,
                    case
                    when r.method like '%\_test' then 'Test'
                    when r.method like '%\_confint' then 'CI'
                    else r.method
                    end as
                method_kind
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



delete
from    saef.ab_result
;





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
;


select  t.ab_test_id,
        m.ab_metric_id as metric_id,
        m.ab_metric_name as metric
from    dma.v_ab_test           t
join    dma.v_ab_test_metric    m   on  m.ab_test_id = t.ab_test_id
where   t.is_active
    and m.ab_test_metric_link_is_active
    and m.ab_metric_is_active
    and t.status in ('Ready for DWH', 'In progress', 'Interrupted', 'Ended')
    and t.ab_test_id = 1450500001
;


select  *
from    dma.v_ab_test        t
join    dma.v_ab_split_group sg on sg.ab_test_id = t.ab_test_id
join    dma.v_ab_period p on p.ab_test_id = t.ab_test_id
where   t.ab_test_ext_id = 133
;


select  observation_date, observation_name, count(*) as cnt
from    dma.ab_observation
where   ab_split_group_id = 1452000001
    and 
group by 1, 2
;


select  *
from    saef.tv_ab_central
where   ab_test_ext_id = 133
;



with
ab_observation as (
    select  o.participant_id,
            o.ab_period_id,
            sum(o.observation_value) as observation_value,
            min(o.observation_date) as min_date,
            max(o.observation_date) as max_date
    from    dma.ab_observation o
    where   o.observation_name in ('phone_views', 'first_messages')
        and o.observation_date <= '2018-06-11'
        and o.is_after_first_exposure
    group by 1, 2
),
ab_participant as (
    select  p.participant_id,
            p.ab_test_id,
            p.ab_period_id,
            p.ab_split_group_id
    from    dma.ab_participant p
    where   true--p.first_exposure_time::date <= '2018-06-11'
        and p.event_date <= '2018-06-11'
        and p.ab_test_id = 1450500001
        and p.ab_period_id = 1448500001
    group by 1, 2, 3, 4
)
select  o.ab_period_id as period_id,
        o.ab_split_group_id as split_group_id,
        o.observation_value,
        cnt
from (
    select  p.ab_period_id,
            p.ab_split_group_id,
            coalesce(o.observation_value, 0) as observation_value,
            count(*) as cnt,
            min(min(o.min_date)) over(partition by p.ab_period_id) as min_date,
            max(max(o.max_date)) over(partition by p.ab_period_id) as max_date
    from    ab_participant      p
    left join ab_observation    o   on  o.participant_id = p.participant_id
                                    and o.ab_period_id = p.ab_period_id
    group by 1, 2, 3
) o
join    dma.v_ab_period     p  on  p.ab_period_id = o.ab_period_id
where   min_date = p.start_time::date
    and max_date = '2018-06-11'
order by 1, 2
;


select  p.ab_test_id,
        p.ab_period_id,
        p.ab_split_group_id,
        p.event_date,
        count(*) as cnt,
        count(first_exposure_time) as exposed
from    dma.ab_participant p
where   true
    and p.ab_test_id = 1095750001
--    and p.ab_period_id = 1448500001
--    and p.ab_split_group_id = 1452000001
group by 1, 2, 3, 4
;

select  p.event_date,
        count(*) as cnt,
        count(first_exposure_time) as exposed
from    dma.ab_participant p
where   true
group by 1
;


select  p.ab_test_id,
        t.ab_test_ext_id,
        t.ab_test_label,
        t.traffic_percent,
        t.salt,
        p.event_date,
        count(*) as cnt,
        count(p.first_exposure_time) as exposed,
        min(p.first_exposure_time) as min_exp_time,
        max(p.first_exposure_time) as max_exp_time
from    dma.ab_participant p
join    dma.v_ab_period    pr on pr.ab_period_id = p.ab_period_id
join    dma.v_ab_test      t  on t.ab_test_id = p.ab_test_id
where   true
    and pr.period not in ('AA_retro')
group by 1, 2, 3, 4, 5, 6
;


select  *
from    dma.v_ab_test_period_date

select  t.ab_test_label, max(p.end_time) as end_time
from    dma.v_ab_test   t
join    dma.v_ab_period p on p.ab_test_id = t.ab_test_id
group by 1
;


where   ab_test_id = 1177500001
;



select  *
from    DMA.v_ab_test_period_date


delete from saef.ab_result where calc_date between '2018-06-14' and '2018-06-18';



select  *
from    dma.ab_observation
where   observation_name = 'phone_views_anon_number'
;




with
ab_observation as (
    select  o.participant_id,
            o.ab_period_id,
            sum(o.observation_value) as observation_value,
            min(o.observation_date) as min_date,
            max(o.observation_date) as max_date
    from    dma.ab_observation o
    where   o.observation_name in ('phone_views')
        and o.observation_date <= '2018-05-25'
        and o.is_after_first_exposure
    group by 1, 2
),
ab_participant as (
    select  p.participant_id,
            p.ab_test_id,
            p.ab_period_id,
            p.ab_split_group_id
    from    dma.ab_participant p
    where   p.first_exposure_time::date <= '2018-05-25'
        and p.event_date <= '2018-05-25'
    group by 1, 2, 3, 4
)
select  o.ab_period_id as period_id,
        o.ab_split_group_id as split_group_id,
        o.observation_value,
        cnt
from (
    select  p.ab_period_id,
            p.ab_split_group_id,
            coalesce(o.observation_value, 0) as observation_value,
            count(*) as cnt,
            min(min(o.min_date)) over(partition by p.ab_period_id) as min_date,
            max(max(o.max_date)) over(partition by p.ab_period_id) as max_date
    from    ab_participant      p
    left join ab_observation    o   on  o.participant_id = p.participant_id
                                    and o.ab_period_id = p.ab_period_id
    group by 1, 2, 3
) o
join    dma.v_ab_period     p  on  p.ab_period_id = o.ab_period_id
where   min_date = p.start_time::date
    and max_date = '2018-05-25'
order by 1, 2
;



with
ab_observation as (
    select  ab_period_id,
            ab_split_group_id,
            observation_value,
            count(*) as cnt,
            min(min(o.min_date)) over(partition by o.ab_period_id) as min_date,
            max(max(o.max_date)) over(partition by o.ab_period_id) as max_date
    from (
        select  o.participant_id,
                o.ab_split_group_id,
                o.ab_period_id,
                sum(o.observation_value) as observation_value,
                min(o.observation_date) as min_date,
                max(o.observation_date) as max_date
        from    dma.ab_observation o
        where   o.observation_name in ('phone_views')
            and o.observation_date <= '2018-05-25'
            and o.is_after_first_exposure
        group by 1, 2, 3
    ) o
    group by 1, 2, 3
),
ab_observation_nonzero as (
    select  ab_period_id,
            ab_split_group_id,
            sum(cnt) as cnt,
            min(min_date) as min_date,
            max(max_date) as max_date
    from    ab_observation
    group by 1, 2
),
ab_observation_zero as (
    select  p.ab_period_id,
            p.ab_split_group_id,
            0,
            p.cnt - zeroifnull(o.cnt) as cnt,
            min(o.min_date) over(partition by p.ab_period_id) as min_date,
            max(o.max_date) over(partition by p.ab_period_id) as max_date
    from (
        select  p.ab_period_id,
                p.ab_split_group_id,
                count(*) as cnt
        from (
            select  p.participant_id,
                    p.ab_test_id,
                    p.ab_period_id,
                    p.ab_split_group_id
            from    dma.ab_participant p
            where   p.first_exposure_time::date <= '2018-05-25'
                and p.event_date <= '2018-05-25'
            group by 1, 2, 3, 4
        ) p
        group by 1, 2
    ) p
    left join ab_observation_nonzero o on  o.ab_period_id = p.ab_period_id
                                       and o.ab_split_group_id = p.ab_split_group_id
    where   p.cnt - zeroifnull(o.cnt) > 0
)
select  o.ab_period_id as period_id,
        o.ab_split_group_id as split_group_id,
        o.observation_value,
        cnt
from (
    select * from ab_observation union all
    select * from ab_observation_zero
) o
join    dma.v_ab_period     p  on  p.ab_period_id = o.ab_period_id
where   min_date = p.start_time::date
    and max_date = '2018-05-25'
order by 1, 2
;


