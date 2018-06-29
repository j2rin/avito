drop table saef.ab_breakdown_text;
create table saef.ab_breakdown_text (
    breakdown_id int,
    breakdown_json varchar(1000),
    breakdown_text varchar(1000),
    insert_time timestamp
) order by breakdown_id segmented by hash(breakdown_id) all nodes;

drop table if exists saef.ab_result;
create table saef.ab_result (
    iter_hash int,
    ab_test_id int,
    period_id int,
    metric_id int,
    metric varchar(64),
    calc_date date,
    split_group_id int,
    control_split_group_id int,
    breakdown_id int,
    class_name varchar(64),
    method varchar(64),
    stat_func varchar(64),
    comp_func varchar(64),
    null_value float,
    alternative varchar(10),
    alpha float,
    is_pivotal boolean,
    resampling varchar(64),
    variance varchar(64),
    n_iters int,
    ratio boolean,
    mean float,
    std float,
    sum float,
    n_obs float,
    p_value float,
    test_statistic float,
    lower_bound float,
    upper_bound float,
    stat_val float,
    std_stat_val float,
    elapsed_seconds float,
    insert_time timestamp
) order by iter_hash segmented by hash(iter_hash) all nodes;

alter table saef.ab_result drop breakdown;