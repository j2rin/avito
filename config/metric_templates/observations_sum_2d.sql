with
ab_observation as (
    select  o.ab_period_id,
            o.ab_split_group_id,
            o.breakdown_id,
            o.numenator_value,
            o.denominator_value,
            o.cnt
    from (
        select  ab_period_id,
                ab_split_group_id,
                breakdown_id,
                numenator_value,
                denominator_value,
                count(*) as cnt,
                sum(numenator_value) over(partition by o.ab_period_id) as numenator_sum,
                sum(denominator_value) over(partition by o.ab_period_id) as denominator_sum
        from (
            select  o.participant_id,
                    o.ab_split_group_id,
                    o.ab_period_id,
                    o.breakdown_id,
                    sum(case when o.observation_name in ({numenator_str}) then o.observation_value else 0 end) as numenator_value,
                    sum(case when o.observation_name in ({denominator_str}) then o.observation_value else 0 end) as denominator_value
            from    dma.ab_observation o
            where   o.observation_name in ({observations_str})
                and o.observation_date <= '{calc_date}'
                and o.is_after_first_exposure
            group by 1, 2, 3, 4
        ) o
        group by 1, 2, 3, 4, 5
    ) o
    where   numenator_sum > 0
        and denominator_sum > 0
),
ab_observation_nonzero as (
    select  ab_period_id,
            ab_split_group_id,
            breakdown_id,
            sum(cnt) as cnt
    from    ab_observation
    group by 1, 2, 3
),
ab_observation_zero as (
    select  p.ab_period_id,
            p.ab_split_group_id,
            o.breakdown_id,
            0, 0,
            p.cnt - zeroifnull(o.cnt) as cnt
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
    join ab_observation_nonzero o   on  o.ab_period_id = p.ab_period_id
                                    and o.ab_split_group_id = p.ab_split_group_id
    where   p.cnt - zeroifnull(o.cnt) > 0
)
select  o.ab_period_id as period_id,
        o.ab_split_group_id as split_group_id,
        o.breakdown_id,
        o.numenator_value,
        o.denominator_value,
        cnt
from (
    select * from ab_observation union all
    select * from ab_observation_zero
) o
order by 1, 2
;