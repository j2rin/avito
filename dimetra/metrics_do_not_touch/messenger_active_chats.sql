create fact messenger_active_chats as
select
    t.event_date::date as __date__,
    *
from dma.vo_messenger_messages t
;

create metrics messenger_active_chats as
select
    sum(case when item_id is not null and chat_subtype is null and IsTest = False then 1 end) as cnt_messenger_active_chats,
    sum(case when is_chatbot_chat = True and ((IsTest = False or IsTest is null) and (eventtype_id = 289341250001 or eventtype_id = 160844250001)) then 1 end) as cnt_messenger_active_chats_with_bot,
    sum(case when chat_subtype = 'support' and IsTest = False then 1 end) as cnt_messenger_support_chats,
    sum(case when chat_type = 'u2u' and IsTest = False then 1 end) as cnt_messenger_u2u_active_chats
from messenger_active_chats t
;

create metrics messenger_active_chats_chat as
select
    sum(case when cnt_messenger_active_chats > 0 then 1 end) as messenger_active_chats,
    sum(case when cnt_messenger_active_chats_with_bot > 0 then 1 end) as messenger_active_chats_with_bot,
    sum(case when cnt_messenger_support_chats > 0 then 1 end) as messenger_support_chats,
    sum(case when cnt_messenger_u2u_active_chats > 0 then 1 end) as messenger_u2u_active_chats
from (
    select
        zero, chat_id,
        sum(case when item_id is not null and chat_subtype is null and IsTest = False then 1 end) as cnt_messenger_active_chats,
        sum(case when is_chatbot_chat = True and ((IsTest = False or IsTest is null) and (eventtype_id = 289341250001 or eventtype_id = 160844250001)) then 1 end) as cnt_messenger_active_chats_with_bot,
        sum(case when chat_subtype = 'support' and IsTest = False then 1 end) as cnt_messenger_support_chats,
        sum(case when chat_type = 'u2u' and IsTest = False then 1 end) as cnt_messenger_u2u_active_chats
    from messenger_active_chats t
    group by zero, chat_id
) _
;
