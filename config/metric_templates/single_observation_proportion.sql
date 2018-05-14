select  o.ab_split_group_id as split_group_id,
        o.observation_value as {observations[0]},
        count(*) as cnt
from (
    select  p.participant_id,
            p.ab_split_group_id,
            coalesce((sum(o.observation_value) > 0)::int, 0) as observation_value,
            min(min(o.observation_date)) over() as min_date,
            max(max(o.observation_date)) over() as max_date
    from    dma.ab_participant      p
    left join dma.ab_observation    o   on  o.participant_id = p.participant_id
                                        and o.ab_period_id = p.ab_period_id
                                        and o.observation_date <= '{calc_date}'
                                        and o.observation_name = '{observations[0]}'
                                        and o.is_after_first_exposure
    where   p.ab_test_id = {ab_test_id}
        and p.ab_period_id = {period_id}
        and p.first_exposure_time::date <= '{calc_date}'
    group by 1,2
) o
where   min_date = '{start_date}'
    and max_date = '{calc_date}'
group by 1,2
;