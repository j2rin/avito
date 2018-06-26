select  *
from    dma.v_ab_test
where   ab_test_id = 532250001
;

select  event_date, count(*) as cnt, count(first_exposure_time) as exps
from    dma.ab_participant
where   ab_test_id = 532250001
group by 1


select  observation_date, observation_name, count(*) as cnt
from    dma.ab_observation
where   ab_test_id = 532250001
--    and observation_name = 'favorites_list_views'
group by 1, 2
;

select  *
from    dma.ab_observation_4147_1


select  *
from    dma.v_ab_test_metric_breakdown


select  *
from    dma.v_ab_test

where   ab_test_ext_id = 143