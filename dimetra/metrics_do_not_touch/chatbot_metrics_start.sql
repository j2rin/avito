create fact chatbot_metrics_start as
select
    t.start_flow_time::date as __date__,
    *
from dma.vo_chatbot_metrics t
;

create metrics chatbot_metrics_start_chat as
select
    sum(case when cnt_a2u_chats > 0 then 1 end) as a2uchat_start_flows,
    sum(case when cnt_u2i_chats > 0 then 1 end) as u2ichat_start_flows
from (
    select
        user_id, chat_id,
        sum(case when chat_type = 'a2u' then 1 end) as cnt_a2u_chats,
        sum(case when chat_type = 'u2i' then 1 end) as cnt_u2i_chats
    from chatbot_metrics_start t
    group by user_id, chat_id
) _
;

create metrics chatbot_metrics_start as
select
    sum(case when chat_type = 'a2u' then 1 end) as cnt_a2u_chats,
    sum(case when chat_type = 'u2i' then 1 end) as cnt_u2i_chats,
    sum(case when transitions = 1 then 1 end) as flows_1_transitions,
    sum(case when transitions = 0 then 1 end) as flows_no_interaction,
    sum(case when start_flow_time is not null then 1 end) as started_flows,
    sum(case when is_support_chat = True and start_flow_time is not null then 1 end) as started_support_flows
from chatbot_metrics_start t
;

create metrics chatbot_metrics_start_user as
select
    sum(case when started_flows > 0 then 1 end) as user_start_flows
from (
    select
        user_id,
        sum(case when start_flow_time is not null then 1 end) as started_flows
    from chatbot_metrics_start t
    group by user_id
) _
;
