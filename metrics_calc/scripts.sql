sql_pg_ab_metric_params: |
    select  t.ab_test_id as ab_test_ext,
            m.metric,
            m.params
    from    ab_config.ab_metric m
    join    ab_config.ab_test   t   on t.ab_test_id = m.ab_test_id
    where   t.is_active
        and m.is_active
        and t.status in ('Ready for DWH', 'In progress', 'Interrupted', 'Ended')
    ;

sql_ab_test: |
    select  t.ab_test_id,
            t.ab_test_ext_id as ab_test_ext,
            t.ab_test_label
    from    dma.v_ab_test t
    where   t.is_active
        and t.status in ('Ready for DWH', 'In progress', 'Interrupted', 'Ended')
    ;

sql_ab_metric: |
    select  t.ab_test_id,
            m.ab_metric_id as metric_id,
            m.ab_metric_name as metric
    from    dma.v_ab_test           t
    join    dma.v_ab_test_metric    m   on  m.ab_test_id = t.ab_test_id
    where   t.is_active
        and m.ab_test_metric_link_is_active
        and m.ab_metric_is_active
        and t.status in ('Ready for DWH', 'In progress', 'Interrupted', 'Ended')
    ;

sql_ab_period: |
    select  t.ab_test_id,
            p.ab_period_id as period_id,
            p.period,
            p.start_time::date as start_date,
                case
                when t.interrupt_time is not null then t.interrupt_time 
                when p.end_time::date <= current_date - interval'1 day' then p.end_time::date
                else current_date - interval'1 day'
                end as
            end_date
    from    dma.v_ab_test   t
    join    dma.v_ab_period p on p.ab_test_id = t.ab_test_id
    where   p.is_active
        and t.is_active
        and t.status in ('Ready for DWH', 'In progress', 'Interrupted', 'Ended')
    ;

sql_ab_split_group: |
    select  t.ab_test_id,
            sg.ab_split_group_id as split_group_id,
            sg.split_group,
            sg.is_control
    from    dma.v_ab_split_group    sg
    join    dma.v_ab_test           t   on  t.ab_test_id = sg.ab_test_id
    where   sg.is_active
        and t.is_active
        and t.status in ('Ready for DWH', 'In progress', 'Interrupted', 'Ended')
    ;

sql_ab_split_group_pair: |
    select  t.ab_test_id,
            sg.ab_split_group_id as split_group_id,
            sg.split_group,
            csg.ab_split_group_id as control_split_group_id,
            csg.split_group as control_split_group
    from    dma.v_ab_split_group    sg
    join    dma.v_ab_split_group    csg on  csg.ab_test_id = sg.ab_test_id
                                        and csg.is_control
                                        and csg.is_active
                                        and csg.ab_split_group_id <> sg.ab_split_group_id
    join    dma.v_ab_test           t   on  t.ab_test_id = sg.ab_test_id
    where   sg.is_active
        and t.is_active
        and t.status in ('Ready for DWH', 'In progress', 'Interrupted', 'Ended')
    ;


sql_create_result_table: |
    drop table if exists saef.ab_result;
    create table saef.ab_result (
        iter_hash int,
        ab_test_id int,
        period_id int,
        metric_id int,
        metric varchar(64),
        start_date date,
        calc_date date,
        split_group_id int,
        control_split_group_id int,
        class_name varchar(64),
        method varchar(64),
        stat_func varchar(64),
        comp_func varchar(64),
        null_value float,
        alternative varchar(10),
        alpha float,
        is_pivotal boolean,
        n_iters int,
        mean float,
        std float,
        n_obs float,
        p_value float,
        test_statistic float,
        lower_bound float,
        upper_bound float,
        elapsed_seconds float,
        insert_datetime timestamp
    ) order by ab_test_id, period_id, metric_id, calc_date, split_group_id, control_split_group_id
    segmented by hash(ab_test_id, period_id, metric_id, calc_date, split_group_id, control_split_group_id) all nodes;


sql_iters_to_skip: |
    select  r.iter_hash
    from    saef.ab_result r
    join    dma.v_ab_test  t on t.ab_test_id = r.ab_test_id
    where   t.is_active
        and t.status in ('Ready for DWH', 'In progress', 'Interrupted', 'Ended')
    ;