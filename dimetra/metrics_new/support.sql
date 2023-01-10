create fact support_fact as
select
    t.event_date::date as __date__,
    *
from dma.vo_support t
;

create metrics support_metrics as
select
    sum(tickets_problem_changed) as cnt_tickets_problem_changed,
    sum(ticket_agent_created) as support_agent_tickets_created,
    sum(ifnull(ticket_automated, 0) + ifnull(chats_automated, 0)) as support_automated,
    sum(ticket_call_reviews) as support_call_reviews,
    sum(ticket_call_created) as support_call_tickets_created,
    sum(callcenter_calls) as support_callcenter_calls,
    sum(chat_csat_scores) as support_chat_csat_scores,
    sum(chat_ht) as support_chat_ht,
    sum(chat_satisfaction_scores) as support_chat_satisfaction_scores,
    sum(chats_automated) as support_chats_automated,
    sum(chats_created) as support_chats_created,
    sum(chats_flow) as support_chats_flow,
    sum(chat_fully_automated) as support_chats_fully_automated,
    sum(chats_partly_automated) as support_chats_partly_automated,
    sum(chats_reviews) as support_chats_reviews,
    sum(chats_with_ht) as support_chats_with_ht,
    sum(ticket_email_created) as support_email_tickets_created,
    sum(ifnull(ticket_email_created, 0) + ifnull(ticket_wizard_created, 0)) as support_email_wizard_tickets_created,
    sum(ifnull(ticket_anonnumber_nodes, 0) + ifnull(call_anonnumber_nodes, 0) + ifnull(chat_anonnumber_nodes, 0)) as support_flow_anonnumber_nodes,
    sum(ifnull(ticket_anonnumber_templates, 0) + ifnull(call_anonnumber_nodes, 0) + ifnull(chat_anonnumber_templates, 0)) as support_flow_anonnumber_templates,
    sum(ifnull(ticket_calltracking_nodes, 0) + ifnull(call_calltracking_nodes, 0) + ifnull(chat_calltracking_nodes, 0)) as support_flow_calltracking_nodes,
    sum(ifnull(ticket_calltracking_templates, 0) + ifnull(call_calltracking_nodes, 0)) as support_flow_calltracking_templates,
    sum(ifnull(ticket_reviews, 0) + ifnull(ticket_call_reviews, 0) + ifnull(chats_reviews, 0)) as support_flow_reviews,
    sum(ifnull(ticket_fully_automated, 0) + ifnull(chat_fully_automated, 0)) as support_fully_automated,
    sum(ifnull(ticket_wizard_created, 0) + ifnull(chats_created, 0)) as support_ticket_chat_platform,
    sum(ticket_csat_scores) as support_ticket_csat_scores,
    sum(ticket_ht) as support_ticket_ht,
    sum(ticket_information_request) as support_ticket_information_request,
    sum(ticket_platform_fraud_nodes) as support_ticket_platform_fraud_nodes,
    sum(ticket_platform_fraud_templates) as support_ticket_platform_fraud_templates,
    sum(ticket_platform_fraud_templates_nodes) as support_ticket_platform_fraud_templates_nodes,
    sum(ticket_reviews) as support_ticket_reviews,
    sum(ticket_satisfaction_scores) as support_ticket_satisfaction_scores,
    sum(ticket_automated) as support_tickets_automated,
    sum(ticket_flow) as support_tickets_flow,
    sum(ticket_fully_automated) as support_tickets_fully_automated,
    sum(ticket_partly_automated) as support_tickets_partly_automated,
    sum(tickets_problem_changed) as support_tickets_problem_changed,
    sum(tickets_with_ht) as support_tickets_with_ht,
    sum(ifnull(ticket_wizard_created, 0) + ifnull(ticket_email_created, 0) + ifnull(chats_created, 0) + ifnull(callcenter_calls, 0)) as support_total_flow,
    sum(ticket_wizard_created) as support_wizard_tickets_created
from support t
;

create metrics support_participant as
select
    sum(case when support_total_flow > 0 then 1 end) as support_contacters
from (
    select
        cookie_id, participant_id,
        sum(ifnull(ticket_wizard_created, 0) + ifnull(ticket_email_created, 0) + ifnull(chats_created, 0) + ifnull(callcenter_calls, 0)) as support_total_flow
    from support_fact t
    group by cookie_id, participant_id
) _
;