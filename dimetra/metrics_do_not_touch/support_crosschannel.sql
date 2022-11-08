create fact support_crosschannel as
select
    t.event_date::date as __date__,
    *
from dma.vo_support_crosschannel t
;

create metrics support_crosschannel as
select
    sum(interaction_automated) as support_interaction_automated,
    sum(interaction_created) as support_interaction_created,
    sum(interaction_flow) as support_interaction_flow,
    sum(interaction_fully_automated) as support_interaction_fully_automated,
    sum(interaction_partly_automated) as support_interaction_partly_automated,
    sum(interaction_resolved) as support_interaction_resolved,
    sum(interaction_resolved_fcr) as support_interaction_resolved_fcr,
    sum(interaction_resolved_not_fcr) as support_interaction_resolved_not_fcr,
    sum(ifnull(interaction_flow, 0) + ifnull(interaction_fully_automated, 0)) as support_interaction_total_flow
from support_crosschannel t
;

create metrics support_crosschannel_participant as
select
    sum(case when support_interaction_created > 0 then 1 end) as support_interaction_contacters
from (
    select
        cookie_id, participant_id,
        sum(interaction_created) as support_interaction_created
    from support_crosschannel t
    group by cookie_id, participant_id
) _
;
