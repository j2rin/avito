with /*+ENABLE_WITH_CLAUSE_MATERIALIZATION*/
ab_observation as (
    select  *
    from    (
        select  o.ab_period_id,
                o.ab_split_group_id,
                o.breakdown_id,
                e.exposed_only,
                    case
                    when e.exposed_only then o.numerator_value_exposed
                    else o.numerator_value
                    end as
                numerator_value,
                    case
                    when e.exposed_only then o.denominator_value_exposed
                    else o.denominator_value
                    end as
                denominator_value,
                count(*) as cnt
        from (
            select  o.participant_id,
                    o.ab_split_group_id,
                    o.ab_period_id,
                    o.breakdown_id,
                    sum(case when o.observation_name in ({numerator_str}) then o.observation_value else 0 end) as numerator_value,
                    sum(case when o.observation_name in ({denominator_str}) then o.observation_value else 0 end) as denominator_value,
                    sum(case when o.observation_name in ({numerator_str}) and o.is_after_first_exposure then o.observation_value else 0 end) as numerator_value_exposed,
                    sum(case when o.observation_name in ({denominator_str}) and o.is_after_first_exposure then o.observation_value else 0 end) as denominator_value_exposed
            from    dma.ab_observation o
            where   o.observation_name in ({observations_str})
                and o.observation_date <= '{calc_date}'
            group by 1, 2, 3, 4
        ) o
        join (
            select  true as exposed_only union all
            select  false as exposed_only
        ) e on true
        group by 1, 2, 3, 4, 5, 6
    ) o
    where   (numerator_value > 0 or denominator_value > 0)
),
ab_observation_nonzero as (
    select  ab_period_id,
            ab_split_group_id,
            breakdown_id,
            exposed_only,
            sum(cnt) as cnt
    from    ab_observation
    group by 1, 2, 3, 4
),
ab_observation_zero as (
    select  p.ab_period_id,
            p.ab_split_group_id,
            o.breakdown_id,
            p.exposed_only,
            0 as numerator_value, 0 as denominator_value,
            p.cnt - zeroifnull(o.cnt) as cnt
    from    (
        select  p.ab_period_id,
                p.ab_split_group_id,
                e.exposed_only,
                    case
                    when e.exposed_only then p.exposed_cnt
                    else p.cnt
                    end as
                cnt 
        from    (
            select  p.ab_period_id,
                    p.ab_split_group_id,
                    count(*) as cnt,
                    sum(p.is_exposed::int) as exposed_cnt
            from (
                select  p.participant_id,
                        p.ab_test_id,
                        p.ab_period_id,
                        p.ab_split_group_id,
                        max(p.first_exposure_time::date <= '{calc_date}') as is_exposed
                from    dma.ab_participant p
                where   p.event_date <= '{calc_date}'
                group by 1, 2, 3, 4
            ) p
            group by 1, 2
        ) p
        join (
            select  true as exposed_only union all
            select  false as exposed_only
        ) e on true
    ) p
    join ab_observation_nonzero o   on  o.ab_period_id = p.ab_period_id
                                    and o.ab_split_group_id = p.ab_split_group_id
                                    and o.exposed_only = p.exposed_only
    where   p.cnt - zeroifnull(o.cnt) > 0
)
select  o.ab_period_id as period_id,
        o.ab_split_group_id as split_group_id,
        o.breakdown_id,
        o.exposed_only,
        o.numerator_value,
        o.denominator_value,
        cnt
from (
    select * from ab_observation union all
    select * from ab_observation_zero
) o
order by 1, 2, 3, 4
;