select  *
from    dma.v_ab_test
where   ab_test_id = 532250001
;

select  event_date, count(*) as cnt, count(first_exposure_time) as exps
from    dma.ab_participant
where   ab_test_id = 532250001
group by 1


select  observation_date, observation_name, count(*) as cnt
from    dma.ab_observation
where   ab_test_id = 532250001
--    and observation_name = 'favorites_list_views'
group by 1, 2
;

select  *
from    dma.ab_observation_4147_1


select  *
from    dma.v_ab_test_metric_breakdown


select  *
from    dma.v_ab_test

where   ab_test_ext_id = 143


select  count(*)
from    dma.ab_observation_4147


create table public.dl_ab_obs_test_new as (

    with
    ab_observation as (
        select  ab_period_id,
                ab_split_group_id,
                breakdown_id,
                observation_value,
                count(*) as cnt,
                min(min(o.min_date)) over(partition by o.ab_period_id) as min_date,
                max(max(o.max_date)) over(partition by o.ab_period_id) as max_date
        from (
            select  o.participant_id,
                    o.ab_split_group_id,
                    o.ab_period_id,
                    o.breakdown_id,
                    sum(o.observation_value) as observation_value,
                    min(o.observation_date) as min_date,
                    max(o.observation_date) as max_date
            from    dma.ab_observation_4147 o
            where   o.observation_name in ('phone_views')
                and o.observation_date <= '2018-05-01'
                and o.is_after_first_exposure
                --and o.ab_period_id = 791750001
                and o.ab_split_group_id = 789750002
            group by 1, 2, 3, 4
        ) o
        group by 1, 2, 3, 4
    ),
    ab_observation_nonzero as (
        select  ab_period_id,
                ab_split_group_id,
                breakdown_id,
                sum(cnt) as cnt,
                min(min_date) as min_date,
                max(max_date) as max_date
        from    ab_observation
        group by 1, 2, 3
    ),
    ab_observation_zero as (
        select  p.ab_period_id,
                p.ab_split_group_id,
                o.breakdown_id,
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
                where   p.first_exposure_time::date <= '2018-05-01'
                    and p.event_date <= '2018-05-01'
                group by 1, 2, 3, 4
            ) p
            group by 1, 2
        ) p
        join ab_observation_nonzero o  on  o.ab_period_id = p.ab_period_id
                                       and o.ab_split_group_id = p.ab_split_group_id
        where   p.cnt - zeroifnull(o.cnt) > 0
    )
    select  o.ab_period_id as period_id,
            o.ab_split_group_id as split_group_id,
            o.breakdown_id,
            o.observation_value,
            cnt
    from (
        select * from ab_observation union all
        select * from ab_observation_zero
    ) o
    join    dma.v_ab_period p   on  p.ab_period_id = o.ab_period_id
    where   '2018-05-01' between p.start_time::date and p.end_time::date
        and min_date = p.start_time::date
        and max_date = '2018-05-01'
    
) order by period_id, split_group_id, breakdown_id, observation_value segmented by hash(period_id, split_group_id, breakdown_id, observation_value) all nodes;


select  sum(cnt * observation_value)
from    public.dl_ab_obs_test           o

select  sum(cnt * observation_value)
from    public.dl_ab_obs_test_new           o


full join   public.dl_ab_obs_test_new   n on n.period_id = o.period_id
                                          and n.split_group_id = o.split_group_id
                                          and n.observation_value = o.observation_value
                                          and n.cnt = o.cnt

                                          
select  *
from    public.dl_ab_obs_test_new
where   period_id = 791750001
    and split_group_id = 789750002
;

                                          
select  *
from    dma.ab_observation
where   ab_period_id = 531250001
    and ab_split_group_id = 532500001
    
select  *
from    dma.ab_observation_4147
where   ab_period_id = 531250001
    and ab_split_group_id = 532500001

    
select  *
from    dma.v_ab_split_group sg
join    dma.v_ab_test t on t.ab_test_id = sg.ab_test_id
where   sg.ab_split_group_id = 789750002



select  *
from    dma.v_ab_test_metric_breakdown


select  t.ab_test_id,
        t.ab_test_ext_id as ab_test_ext,
        t.ab_test_label,
        m.ab_metric_id as metric_id,
        m.ab_metric_name as metric,
        p.ab_period_id as period_id,
        p.period,
        p.start_time::date as start_date,
            case
            when t.interrupt_time is not null then t.interrupt_time 
            when p.end_time::date <= current_date - interval'1 day' then p.end_time::date
            else current_date - interval'1 day'
            end::date as
        end_date,
        b.breakdown_id,
        d.event_date as calc_date
from    dma.v_ab_test                   t
join    dma.v_ab_test_metric            m   on  m.ab_test_id = t.ab_test_id
join    dma.v_ab_period                 p   on  p.ab_test_id = t.ab_test_id
join    dma.v_ab_test_period_date       d   on  d.ab_period_id = p.ab_period_id
join    dma.v_ab_test_metric_breakdown  b   on  b.ab_metric_id = m.ab_metric_id
where   t.is_active
    and t.status in ('Ready for DWH', 'In progress', 'Interrupted', 'Ended')
    and m.ab_test_metric_link_is_active
    and m.ab_metric_is_active
    and m.ab_metric_name not in ('saved_searches_list_views')
    and p.is_active
    and p.period not in ('AA_retro')
    and not d.event_date between '2018-06-14' and '2018-06-18'
    and d.event_date < current_date
order by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
;

