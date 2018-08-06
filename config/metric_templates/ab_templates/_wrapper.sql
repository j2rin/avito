insert /*+direct*/ into saef.ab_metrics
select  ab_period_id as period_id,
        ab_split_group_id as split_group_id,
        breakdown_id as breakdown_id,
        exposed_only as exposed_only,
        {metric_id} as metric_id,
        '{calc_date}'::date as calc_date,
        numerator_value,
        denominator_value,
        participants
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
            count(*) as participants
    from (
        {sql}
    ) o
    join (
        select  true as exposed_only union all
        select  false as exposed_only
    ) e on true
    group by 1, 2, 3, 4, 5, 6
) o
where   (numerator_value > 0 or denominator_value > 0)
;
