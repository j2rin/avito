select  o.participant_id,
        o.ab_split_group_id,
        o.ab_period_id,
        o.breakdown_id,
        (sum(o.observation_value) > 0)::int as numerator_value,
        (sum(case when o.is_after_first_exposure then o.observation_value end) > 0)::int as numerator_value_exposed,
        null::float as denominator_value,
        null::float as denominator_value_exposed
from    dma.ab_observation          o
where   o.observation_name in ({observations_str})
    and o.observation_date between '{start_date}' and '{calc_date}'
    and o.ab_period_id = {period_id}
    and o.breakdown_id in ({breakdowns_str})
group by 1, 2, 3, 4