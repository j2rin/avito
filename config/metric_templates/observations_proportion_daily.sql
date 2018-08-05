with /*+ENABLE_WITH_CLAUSE_MATERIALIZATION*/
ab_observation as (
    select  *
    from    (
        select  o.ab_period_id,
                o.ab_split_group_id,
                o.breakdown_id,
                e.exposed_only,
                    case
                    when e.exposed_only then o.observation_value_exposed
                    else o.observation_value
                    end as
                observation_value,
                count(*) as cnt
        from (
            select  o.participant_id,
                    o.ab_split_group_id,
                    o.ab_period_id,
                    o.breakdown_id,
                    (sum(o.observation_value) > 0)::int as observation_value,
                    (sum(case when o.is_after_first_exposure then o.observation_value end) > 0)::int as observation_value_exposed
            from    (
                select  o.participant_id,
                        o.ab_split_group_id,
                        o.ab_period_id,
                        o.breakdown_id,
                        o.observation_date,
                        max(o.is_after_first_exposure) as is_after_first_exposure,
                        (sum(o.observation_value) > 0)::int as observation_value
                from    dma.ab_observation o
                where   o.observation_name in ({observations_str})
                    and o.observation_date <= '{calc_date}'
                group by 1, 2, 3, 4, 5
            ) o
            group by 1, 2, 3, 4
        ) o
        join (
            select  true as exposed_only union all
            select  false as exposed_only
        ) e on true
        group by 1, 2, 3, 4, 5
    ) o
    where   observation_value > 0
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
            0 as observation_value,
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
        o.observation_value,
        cnt
from (
    select * from ab_observation union all
    select * from ab_observation_zero
) o
order by 1, 2, 3, 4
;

