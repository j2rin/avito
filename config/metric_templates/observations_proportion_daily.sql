with
ab_observation as (
    select  o.participant_id,
            o.ab_period_id,
            sum(observation_value) as observation_value,
            min(o.observation_date) as min_date,
            max(o.observation_date) as max_date
    from (
        select  o.participant_id,
                o.ab_period_id,
                o.observation_date,
                coalesce((sum(o.observation_value) > 0)::int, 0) as observation_value
        from    dma.ab_observation o
        where   o.observation_name in ({observations_str})
            and o.observation_date <= '{calc_date}'
            and o.is_after_first_exposure
        group by 1, 2, 3
    ) o
    group by 1, 2
),
ab_participant as (
    select  p.participant_id,
            p.ab_test_id,
            p.ab_period_id,
            p.ab_split_group_id
    from    dma.ab_participant p
    where   p.first_exposure_time::date <= '{calc_date}'
        and p.event_date <= '{calc_date}'
    group by 1, 2, 3, 4
)
select  o.ab_period_id as period_id,
        o.ab_split_group_id as split_group_id,
        o.observation_value as {observations[0]},
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
    and max_date = '{calc_date}'
order by 1, 2
;