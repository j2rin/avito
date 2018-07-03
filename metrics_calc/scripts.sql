pg_ab_metric_params: |
    select  t.ab_test_id as ab_test_ext,
            m.metric,
            m.params
    from    ab_config.ab_metric m
    join    ab_config.ab_test   t   on t.ab_test_id = m.ab_test_id
    /*where   t.is_active
        and m.is_active
        and t.status in ('Ready for DWH', 'In progress', 'Interrupted', 'Ended')*/
    ;

ab_test: |
    select  t.ab_test_id,
            t.ab_test_ext_id as ab_test_ext,
            t.ab_test_label
    from    dma.v_ab_test t
    where   t.is_active
        and t.status in ('Ready for DWH', 'In progress', 'Interrupted', 'Ended')
    ;

ab_metric: |
    select  ab_test_id,
            metric_id,
            metric
    from    (
        select  t.ab_test_id,
                m.ab_metric_id as metric_id,
                m.ab_metric_name as metric,
                row_number() over(partition by t.ab_test_id, m.ab_metric_id) as rn
        from    dma.v_ab_test           t
        join    dma.v_ab_test_metric    m   on  m.ab_test_id = t.ab_test_id
        where   t.is_active
            and m.ab_test_metric_link_is_active
            and m.ab_metric_is_active
            and t.status in ('Ready for DWH', 'In progress', 'Interrupted', 'Ended')
            and m.ab_metric_name not in ('saved_searches_list_views')
    ) m
    where   rn = 1
    ;

metric: |
    select  ABMetric_id as metric_id, External_ID as metric
    from    dds.H_ABMetric
    ;

ab_period: |
    select  t.ab_test_id,
            p.ab_period_id as period_id,
            p.period,
            p.start_time::date as start_date,
                case
                when t.interrupt_time is not null then t.interrupt_time 
                when p.end_time::date <= current_date - interval'1 day' then p.end_time::date
                else current_date - interval'1 day'
                end::date as
            end_date
    from    dma.v_ab_test   t
    join    dma.v_ab_period p on p.ab_test_id = t.ab_test_id
    where   p.is_active
        and t.is_active
        and t.status in ('Ready for DWH', 'In progress', 'Interrupted', 'Ended')
        and p.period not in ('AA_retro')
    ;

ab_period_date: |
    select  ab_period_id as period_id,
            event_date as calc_date
    from    DMA.v_ab_test_period_date
    where   period not in ('AA_retro')
        and not event_date between '2018-06-14' and '2018-06-18'
        and event_date < current_date
    ;

ab_split_group: |
    select  t.ab_test_id,
            t.ab_test_ext_id as ab_test_ext,
            sg.ab_split_group_id as split_group_id,
            sg.split_group,
            sg.is_control
    from    dma.v_ab_split_group    sg
    join    dma.v_ab_test           t   on  t.ab_test_id = sg.ab_test_id
    where   sg.is_active
        and t.is_active
        and t.status in ('Ready for DWH', 'In progress', 'Interrupted', 'Ended')
    ;

pg_ab_split_group_pair: |
    select  sg.ab_test_id as ab_test_ext,
            sg.split_group,
            sg.split_group_control as control_split_group
    from    ab_config.ab_split_group_comparison sg
    join    ab_config.ab_test                   t   on t.ab_test_id = sg.ab_test_id
    where   sg.is_active
        and t.is_active
        and t.status in ('Ready for DWH', 'In progress', 'Interrupted', 'Ended')
    ;

ab_records: |
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
    from    dma.v_ab_test                    t
    join    dma.v_ab_test_metric             m   on  m.ab_test_id = t.ab_test_id
    join    dma.v_ab_period                  p   on  p.ab_test_id = t.ab_test_id
    join    dma.v_ab_test_period_date        d   on  d.ab_period_id = p.ab_period_id
    join    dma.v_ab_test_metric_breakdown   b   on  b.ab_test_metric_link_id = m.ab_test_metric_link_id
    join    dma.v_ab_test_metric_observation o  on  o.ab_test_metric_link_id = m.ab_test_metric_link_id
    join (
        select  --o.ab_split_group_id as split_group_id,
                o.ab_period_id,
                o.breakdown_id,
                o.observation_name,
                o.observation_date
        from    dma.ab_observation o
        group by 1, 2, 3, 4
    ) oa    on  oa.ab_period_id = p.ab_period_id
            and oa.breakdown_id = b.breakdown_id
            and oa.observation_name = o.ab_observation_name
            and oa.observation_date = d.event_date
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

ab_breakdown_dim_filter: |
    select  f.breakdown_id,
            f.dimension_slug,
            f.dimension_value
    from    dma.v_ab_test_metric_breakdown_dimension_filter f
    where   dimension_value is not null
    order by 1, 2, 3
    ;

iters_to_skip: |
    select  r.iter_hash
    from    saef.ab_result r
    join    dma.v_ab_test  t on t.ab_test_id = r.ab_test_id
    where   t.is_active
        and t.status in ('Ready for DWH', 'In progress', 'Interrupted', 'Ended')
    ;
