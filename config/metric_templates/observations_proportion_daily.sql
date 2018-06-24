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
        from (
            select  o.participant_id,
                    o.ab_split_group_id,
                    o.ab_period_id,
                    o.observation_date,
                    (sum(o.observation_value) > 0)::int as observation_value
            from    dma.ab_observation o
            where   o.observation_name in ({observations_str})
                and o.observation_date <= '{calc_date}'
                and o.is_after_first_exposure
            group by 1, 2, 3, 4
        ) o
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
            where   p.first_exposure_time::date <= '{calc_date}'
                and p.event_date <= '{calc_date}'
            group by 1, 2, 3, 4
        ) p
        group by 1, 2
    ) p
    left join ab_observation_nonzero o  on  o.ab_period_id = p.ab_period_id
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
join    dma.v_ab_period p   on  p.ab_period_id = o.ab_period_id
where   '{calc_date}' between p.start_time::date and p.end_time::date
    and min_date = p.start_time::date
    and max_date = '{calc_date}'
order by 1, 2
;