create or replace view saef.tv_ab_observation_monitor as
with
required as (
    select  t.ab_test_id,
            t.ab_test_ext_id as ab_test_ext,
            t.ab_test_label,
            --sg.ab_split_group_id as split_group_id,
            --sg.split_group,
            o.ab_observation_id as observation_id,
            o.ab_observation_name as observation,
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
            bd.breakdown_text,
            d.event_date as observation_date,
            hash(p.ab_period_id, b.breakdown_id, o.ab_observation_name) as slot_hash
    from    dma.v_ab_test                    t
    join    dma.v_ab_test_metric             m   on  m.ab_test_id = t.ab_test_id
    join    dma.v_ab_test_metric_observation o   on  o.ab_test_metric_link_id = m.ab_test_metric_link_id
    join    dma.v_ab_period                  p   on  p.ab_test_id = t.ab_test_id
    join    dma.v_ab_test_period_date        d   on  d.ab_period_id = p.ab_period_id
    join    dma.v_ab_test_metric_breakdown   b   on  b.ab_test_metric_link_id = m.ab_test_metric_link_id
    --join    dma.v_ab_split_group             sg  on  sg.ab_test_id = t.ab_test_id
    left join   saef.ab_breakdown_text       bd  on  bd.breakdown_id = b.breakdown_id
    where   t.is_active
        and t.status in ('Ready for DWH', 'In progress', 'Interrupted', 'Ended')
        and m.ab_test_metric_link_is_active
        and m.ab_metric_is_active
        and m.ab_metric_name not in ('saved_searches_list_views')
        and p.is_active
        and p.period not in ('AA_retro')
    order by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
),
present as (
    select  --o.ab_split_group_id as split_group_id,
            o.ab_period_id as period_id,
            o.breakdown_id,
            o.observation_name as observation,
            o.observation_date,
            sum(o.observation_value) as observation_value,
            sum(case when o.is_after_first_exposure then o.observation_value else null end) as observation_value_exposed
    from    dma.ab_observation_4147 o
    group by 1, 2, 3, 4, 5
)
select  r.*,
        p.observation_value,
        p.observation_value_exposed
from    required    r
left join   present p   on  p.period_id = r.period_id
                        and p.breakdown_id = r.breakdown_id
                        and p.observation = r.observation
                        and p.observation_date = r.observation_date
;

alter view saef.tv_ab_observation_monitor owner to dbadmin;