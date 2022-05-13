create fact messenger_messages as
select
    t.event_date as __date__,
    t.IsTest,
    t.chat_subtype,
    t.chat_type,
    t.event_date,
    t.eventtype_id,
    t.is_chatbot_chat,
    t.is_first_message,
    t.is_item_owner,
    t.item_id,
    t.message_id as message,
    t.user_id as user,
    t.user_id
from dma.vo_messenger_messages t
;

create metrics messenger_messages as
select
    sum(case when chat_subtype is null and eventtype_id = 119892250001 and IsTest = False then 1 end) as cnt_messenger_auto_messages,
    sum(case when chat_subtype is null and eventtype_id not in (123266750002, 259585250001) and is_item_owner = False and IsTest = False then 1 end) as cnt_messenger_buyer_total_messages,
    sum(case when chat_subtype is null and eventtype_id not in (123266750002, 259585250001) and is_item_owner = False and is_chatbot_chat = True then 1 end) as cnt_messenger_buyer_total_messages_inchat_with_bot,
    sum(case when chat_subtype is null and eventtype_id = 289341250001 then 1 end) as cnt_messenger_chatbot_messages,
    sum(case when chat_subtype is null and eventtype_id = 340504000001 and IsTest = False then 1 end) as cnt_messenger_files_messages,
    sum(case when chat_subtype is null and is_first_message = True and IsTest = False then 1 end) as cnt_messenger_first_messages,
    sum(case when chat_subtype is null and eventtype_id = 173412000001 and IsTest = False then 1 end) as cnt_messenger_geo_messages,
    sum(case when chat_subtype is null and eventtype_id = 123266750001 and IsTest = False then 1 end) as cnt_messenger_image_messages,
    sum(case when chat_subtype is null and eventtype_id = 18250001 and IsTest = False then 1 end) as cnt_messenger_item_messages,
    sum(case when chat_subtype is null and eventtype_id = 173471000001 and IsTest = False then 1 end) as cnt_messenger_links_messages,
    sum(case when chat_subtype is null and eventtype_id not in (123266750002, 259585250001) and is_item_owner = True and IsTest = False then 1 end) as cnt_messenger_seller_total_messages,
    sum(case when chat_subtype is null and eventtype_id not in (123266750002, 259585250001) and is_item_owner = True and is_chatbot_chat = True and IsTest = False then 1 end) as cnt_messenger_seller_total_messages_inchat_with_bot,
    sum(case when chat_subtype is null and eventtype_id = 123266750002 and IsTest = False then 1 end) as cnt_messenger_sendcall_messages,
    sum(case when chat_subtype = 'support' and eventtype_id = 340504000001 and IsTest = False then 1 end) as cnt_messenger_supportchat_files_messages,
    sum(case when chat_subtype = 'support' and eventtype_id = 123266750001 and IsTest = False then 1 end) as cnt_messenger_supportchat_image_messages,
    sum(case when chat_subtype = 'support' and eventtype_id = 18750001 and IsTest = False then 1 end) as cnt_messenger_supportchat_text_messages,
    sum(case when chat_subtype = 'support' and eventtype_id not in (123266750002, 259585250001) and IsTest = False then 1 end) as cnt_messenger_supportchat_total_messeges,
    sum(case when chat_subtype is null and eventtype_id = 18750001 and IsTest = False then 1 end) as cnt_messenger_text_messages,
    sum(case when item_id is not null and chat_subtype is null and eventtype_id not in (123266750002, 259585250001) and IsTest = False then 1 end) as cnt_messenger_total_messeges,
    sum(case when is_chatbot_chat = True and eventtype_id not in (123266750002, 259585250001) then 1 end) as cnt_messenger_total_messeges_inchat_with_bot,
    sum(case when chat_type = 'u2u' and eventtype_id = 123266750001 and IsTest = False then 1 end) as cnt_messenger_u2u_image_messages,
    sum(case when chat_type = 'u2u' and eventtype_id = 123266750002 and IsTest = False then 1 end) as cnt_messenger_u2u_sendcall_messages,
    sum(case when chat_type = 'u2u' and eventtype_id = 18750001 and IsTest = False then 1 end) as cnt_messenger_u2u_text_messages,
    sum(case when chat_type = 'u2u' and eventtype_id not in (123266750002, 259585250001) and IsTest = False then 1 end) as cnt_messenger_u2u_total_messeges,
    sum(case when chat_subtype is null and eventtype_id = 259585250001 and IsTest = False then 1 end) as cnt_messenger_voip_call_message
from messenger_messages t
;

create metrics messenger_messages_message as
select
    sum(case when cnt_messenger_auto_messages > 0 then 1 end) as messenger_auto_messages,
    sum(case when cnt_messenger_buyer_total_messages > 0 then 1 end) as messenger_buyer_total_messages,
    sum(case when cnt_messenger_chatbot_messages > 0 then 1 end) as messenger_chatbot_messages,
    sum(case when cnt_messenger_files_messages > 0 then 1 end) as messenger_files_messages,
    sum(case when cnt_messenger_first_messages > 0 then 1 end) as messenger_first_messages,
    sum(case when cnt_messenger_geo_messages > 0 then 1 end) as messenger_geo_messages,
    sum(case when cnt_messenger_image_messages > 0 then 1 end) as messenger_image_messages,
    sum(case when cnt_messenger_item_messages > 0 then 1 end) as messenger_item_messages,
    sum(case when cnt_messenger_links_messages > 0 then 1 end) as messenger_links_messages,
    sum(case when cnt_messenger_seller_total_messages > 0 then 1 end) as messenger_seller_total_messages,
    sum(case when cnt_messenger_sendcall_messages > 0 then 1 end) as messenger_sendcall_messages,
    sum(case when cnt_messenger_supportchat_files_messages > 0 then 1 end) as messenger_supportchat_files_messages,
    sum(case when cnt_messenger_supportchat_image_messages > 0 then 1 end) as messenger_supportchat_image_messages,
    sum(case when cnt_messenger_supportchat_text_messages > 0 then 1 end) as messenger_supportchat_text_messages,
    sum(case when cnt_messenger_supportchat_total_messeges > 0 then 1 end) as messenger_supportchat_total_messeges,
    sum(case when cnt_messenger_text_messages > 0 then 1 end) as messenger_text_messages,
    sum(case when cnt_messenger_u2u_image_messages > 0 then 1 end) as messenger_u2u_image_messages,
    sum(case when cnt_messenger_u2u_sendcall_messages > 0 then 1 end) as messenger_u2u_sendcall_messages,
    sum(case when cnt_messenger_u2u_text_messages > 0 then 1 end) as messenger_u2u_text_messages,
    sum(case when cnt_messenger_u2u_total_messeges > 0 then 1 end) as messenger_u2u_total_messeges,
    sum(case when cnt_messenger_voip_call_message > 0 then 1 end) as messenger_voip_call_message,
    sum(case when cnt_messenger_total_messeges > 0 then 1 end) as total_messages,
    sum(case when cnt_messenger_total_messeges_inchat_with_bot > 0 then 1 end) as total_messages_chatbot_chat,
    sum(case when cnt_messenger_buyer_total_messages_inchat_with_bot > 0 then 1 end) as total_messages_chatbot_chat_buyer,
    sum(case when cnt_messenger_seller_total_messages_inchat_with_bot > 0 then 1 end) as total_messages_chatbot_chat_seller
from (
    select
        user_id, message,
        sum(case when chat_subtype is null and eventtype_id = 119892250001 and IsTest = False then 1 end) as cnt_messenger_auto_messages,
        sum(case when chat_subtype is null and eventtype_id not in (123266750002, 259585250001) and is_item_owner = False and IsTest = False then 1 end) as cnt_messenger_buyer_total_messages,
        sum(case when chat_subtype is null and eventtype_id not in (123266750002, 259585250001) and is_item_owner = False and is_chatbot_chat = True then 1 end) as cnt_messenger_buyer_total_messages_inchat_with_bot,
        sum(case when chat_subtype is null and eventtype_id = 289341250001 then 1 end) as cnt_messenger_chatbot_messages,
        sum(case when chat_subtype is null and eventtype_id = 340504000001 and IsTest = False then 1 end) as cnt_messenger_files_messages,
        sum(case when chat_subtype is null and is_first_message = True and IsTest = False then 1 end) as cnt_messenger_first_messages,
        sum(case when chat_subtype is null and eventtype_id = 173412000001 and IsTest = False then 1 end) as cnt_messenger_geo_messages,
        sum(case when chat_subtype is null and eventtype_id = 123266750001 and IsTest = False then 1 end) as cnt_messenger_image_messages,
        sum(case when chat_subtype is null and eventtype_id = 18250001 and IsTest = False then 1 end) as cnt_messenger_item_messages,
        sum(case when chat_subtype is null and eventtype_id = 173471000001 and IsTest = False then 1 end) as cnt_messenger_links_messages,
        sum(case when chat_subtype is null and eventtype_id not in (123266750002, 259585250001) and is_item_owner = True and IsTest = False then 1 end) as cnt_messenger_seller_total_messages,
        sum(case when chat_subtype is null and eventtype_id not in (123266750002, 259585250001) and is_item_owner = True and is_chatbot_chat = True and IsTest = False then 1 end) as cnt_messenger_seller_total_messages_inchat_with_bot,
        sum(case when chat_subtype is null and eventtype_id = 123266750002 and IsTest = False then 1 end) as cnt_messenger_sendcall_messages,
        sum(case when chat_subtype = 'support' and eventtype_id = 340504000001 and IsTest = False then 1 end) as cnt_messenger_supportchat_files_messages,
        sum(case when chat_subtype = 'support' and eventtype_id = 123266750001 and IsTest = False then 1 end) as cnt_messenger_supportchat_image_messages,
        sum(case when chat_subtype = 'support' and eventtype_id = 18750001 and IsTest = False then 1 end) as cnt_messenger_supportchat_text_messages,
        sum(case when chat_subtype = 'support' and eventtype_id not in (123266750002, 259585250001) and IsTest = False then 1 end) as cnt_messenger_supportchat_total_messeges,
        sum(case when chat_subtype is null and eventtype_id = 18750001 and IsTest = False then 1 end) as cnt_messenger_text_messages,
        sum(case when item_id is not null and chat_subtype is null and eventtype_id not in (123266750002, 259585250001) and IsTest = False then 1 end) as cnt_messenger_total_messeges,
        sum(case when is_chatbot_chat = True and eventtype_id not in (123266750002, 259585250001) then 1 end) as cnt_messenger_total_messeges_inchat_with_bot,
        sum(case when chat_type = 'u2u' and eventtype_id = 123266750001 and IsTest = False then 1 end) as cnt_messenger_u2u_image_messages,
        sum(case when chat_type = 'u2u' and eventtype_id = 123266750002 and IsTest = False then 1 end) as cnt_messenger_u2u_sendcall_messages,
        sum(case when chat_type = 'u2u' and eventtype_id = 18750001 and IsTest = False then 1 end) as cnt_messenger_u2u_text_messages,
        sum(case when chat_type = 'u2u' and eventtype_id not in (123266750002, 259585250001) and IsTest = False then 1 end) as cnt_messenger_u2u_total_messeges,
        sum(case when chat_subtype is null and eventtype_id = 259585250001 and IsTest = False then 1 end) as cnt_messenger_voip_call_message
    from messenger_messages t
    group by user_id, message
) _
;

create metrics messenger_messages_user as
select
    sum(case when cnt_messenger_buyer_total_messages > 0 then 1 end) as messenger_buyer,
    sum(case when cnt_messenger_buyer_total_messages_inchat_with_bot > 0 then 1 end) as messenger_chatbot_buyer,
    sum(case when cnt_messenger_total_messeges_inchat_with_bot > 0 then 1 end) as messenger_chatbot_dau,
    sum(case when cnt_messenger_seller_total_messages_inchat_with_bot > 0 then 1 end) as messenger_chatbot_seller,
    sum(case when cnt_messenger_total_messeges > 0 then 1 end) as messenger_dau,
    sum(case when cnt_messenger_seller_total_messages > 0 then 1 end) as messenger_seller
from (
    select
        user_id, user,
        sum(case when chat_subtype is null and eventtype_id not in (123266750002, 259585250001) and is_item_owner = False and IsTest = False then 1 end) as cnt_messenger_buyer_total_messages,
        sum(case when chat_subtype is null and eventtype_id not in (123266750002, 259585250001) and is_item_owner = False and is_chatbot_chat = True then 1 end) as cnt_messenger_buyer_total_messages_inchat_with_bot,
        sum(case when chat_subtype is null and eventtype_id not in (123266750002, 259585250001) and is_item_owner = True and IsTest = False then 1 end) as cnt_messenger_seller_total_messages,
        sum(case when chat_subtype is null and eventtype_id not in (123266750002, 259585250001) and is_item_owner = True and is_chatbot_chat = True and IsTest = False then 1 end) as cnt_messenger_seller_total_messages_inchat_with_bot,
        sum(case when item_id is not null and chat_subtype is null and eventtype_id not in (123266750002, 259585250001) and IsTest = False then 1 end) as cnt_messenger_total_messeges,
        sum(case when is_chatbot_chat = True and eventtype_id not in (123266750002, 259585250001) then 1 end) as cnt_messenger_total_messeges_inchat_with_bot
    from messenger_messages t
    group by user_id, user
) _
;
