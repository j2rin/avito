create fact support as
select
    t.call_anonnumber_nodes,
    t.call_calltracking_nodes,
    t.callcenter_calls,
    t.chat_anonnumber_nodes,
    t.chat_anonnumber_templates,
    t.chat_calltracking_nodes,
    t.chats_created,
    t.chats_moder_block_created,
    t.chats_moder_reject_created,
    t.chats_reviews,
    t.cookie_id,
    t.event_date,
    t.participant_id as participant,
    t.ticket_agent_created,
    t.ticket_anonnumber_nodes,
    t.ticket_anonnumber_templates,
    t.ticket_call_created,
    t.ticket_call_moder_block_created,
    t.ticket_call_moder_reject_created,
    t.ticket_call_reviews,
    t.ticket_calltracking_nodes,
    t.ticket_calltracking_templates,
    t.ticket_email_created,
    t.ticket_platform_fraud_nodes,
    t.ticket_platform_fraud_templates,
    t.ticket_platform_fraud_templates_nodes,
    t.ticket_platform_moder_block,
    t.ticket_platform_moder_reject,
    t.ticket_reviews,
    t.ticket_wizard_created,
    t.tickets_problem_changed
from dma.vo_support t
;

create metrics support as
select
    sum(tickets_problem_changed) as cnt_tickets_problem_changed,
    sum(ticket_agent_created) as support_agent_tickets_created,
    sum(ticket_call_reviews) as support_call_reviews,
    sum(ticket_call_moder_block_created) as support_call_ticket_block,
    sum(ifnull(ticket_call_moder_block_created, 0) + ifnull(ticket_call_moder_reject_created, 0)) as support_call_ticket_moder,
    sum(ticket_call_moder_reject_created) as support_call_ticket_reject,
    sum(ticket_call_created) as support_call_tickets_created,
    sum(callcenter_calls) as support_callcenter_calls,
    sum(chats_moder_block_created) as support_chats_block,
    sum(chats_created) as support_chats_created,
    sum(ifnull(chats_moder_block_created, 0) + ifnull(chats_moder_reject_created, 0)) as support_chats_moder,
    sum(chats_moder_reject_created) as support_chats_reject,
    sum(chats_reviews) as support_chats_reviews,
    sum(ticket_email_created) as support_email_tickets_created,
    sum(ifnull(ticket_email_created, 0) + ifnull(ticket_wizard_created, 0)) as support_email_wizard_tickets_created,
    sum(ifnull(ticket_anonnumber_nodes, 0) + ifnull(call_anonnumber_nodes, 0) + ifnull(chat_anonnumber_nodes, 0)) as support_flow_anonnumber_nodes,
    sum(ifnull(ticket_anonnumber_templates, 0) + ifnull(call_anonnumber_nodes, 0) + ifnull(chat_anonnumber_templates, 0)) as support_flow_anonnumber_templates,
    sum(ifnull(ticket_platform_moder_block, 0) + ifnull(ticket_call_moder_block_created, 0) + ifnull(chats_moder_block_created, 0)) as support_flow_block,
    sum(ifnull(ticket_calltracking_nodes, 0) + ifnull(call_calltracking_nodes, 0) + ifnull(chat_calltracking_nodes, 0)) as support_flow_calltracking_nodes,
    sum(ifnull(ticket_calltracking_templates, 0) + ifnull(call_calltracking_nodes, 0)) as support_flow_calltracking_templates,
    sum(ifnull(ticket_platform_moder_block, 0) + ifnull(ticket_call_moder_block_created, 0) + ifnull(chats_moder_block_created, 0) + ifnull(ticket_platform_moder_reject, 0) + ifnull(ticket_call_moder_reject_created, 0) + ifnull(chats_moder_reject_created, 0)) as support_flow_moder,
    sum(ifnull(ticket_platform_moder_reject, 0) + ifnull(ticket_call_moder_reject_created, 0) + ifnull(chats_moder_reject_created, 0)) as support_flow_reject,
    sum(ifnull(ticket_reviews, 0) + ifnull(ticket_call_reviews, 0) + ifnull(chats_reviews, 0)) as support_flow_reviews,
    sum(ticket_platform_moder_block) as support_hc_ticket_platform_block,
    sum(ticket_platform_fraud_nodes) as support_hc_ticket_platform_fraud_nodes,
    sum(ticket_platform_fraud_templates) as support_hc_ticket_platform_fraud_templates,
    sum(ticket_platform_fraud_templates_nodes) as support_hc_ticket_platform_fraud_templates_nodes,
    sum(ifnull(ticket_platform_moder_block, 0) + ifnull(ticket_platform_moder_reject, 0)) as support_hc_ticket_platform_moder,
    sum(ticket_platform_moder_reject) as support_hc_ticket_platform_reject,
    sum(ifnull(ticket_wizard_created, 0) + ifnull(chats_created, 0)) as support_ticket_chat_platform,
    sum(ticket_reviews) as support_ticket_reviews,
    sum(ifnull(ticket_wizard_created, 0) + ifnull(ticket_email_created, 0) + ifnull(chats_created, 0) + ifnull(callcenter_calls, 0)) as support_total_flow,
    sum(ticket_wizard_created) as support_wizard_tickets_created
from support t
;

create metrics support_participant as
select
    sum(case when support_total_flow > 0 then 1 end) as support_contacters
from (
    select
        cookie_id, participant,
        sum(ifnull(ticket_wizard_created, 0) + ifnull(ticket_email_created, 0) + ifnull(chats_created, 0) + ifnull(callcenter_calls, 0)) as support_total_flow
    from support t
    group by cookie_id, participant
) _
;
