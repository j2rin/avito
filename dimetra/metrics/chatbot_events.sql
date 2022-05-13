create fact chatbot_events as
select
    t.event_date as __date__,
    t.event_date,
    t.eventtype_id,
    t.user_id as user,
    t.user_id
from dma.vo_chatbot_events t
;

create metrics chatbot_events as
select
    sum(case when eventtype_id = 390648500001 then 1 end) as chatbot_conflicts,
    sum(case when eventtype_id = 297742000001 then 1 end) as chatbot_transitions
from chatbot_events t
;

create metrics chatbot_events_user as
select
    sum(case when chatbot_transitions > 0 then 1 end) as messenger_chatbot_dau_tr
from (
    select
        user_id, user,
        sum(case when eventtype_id = 297742000001 then 1 end) as chatbot_transitions
    from chatbot_events t
    group by user_id, user
) _
;
