create fact messenger_response_messages as
select
    t.reply_time as __date__,
    t.chat_subtype,
    t.chat_type,
    t.item_id,
    t.reply_message_bot,
    t.reply_time,
    t.user_id as user,
    t.user_id,
    t.with_reply
from dma.vo_messenger_chat_report t
;

create metrics messenger_response_messages as
select
    sum(case when chat_subtype is null and with_reply = True then 1 end) as first_response_messages,
    sum(case when item_id is not null and reply_message_bot = True and with_reply = True then 1 end) as first_response_messages_by_bot,
    sum(case when chat_type = 'u2u' and with_reply = True then 1 end) as first_response_messages_u2u
from messenger_response_messages t
;

create metrics messenger_response_messages_user as
select
    sum(case when first_response_messages > 0 then 1 end) as users_first_response_messages,
    sum(case when first_response_messages_by_bot > 0 then 1 end) as users_first_response_messages_by_bot
from (
    select
        user_id, user,
        sum(case when chat_subtype is null and with_reply = True then 1 end) as first_response_messages,
        sum(case when item_id is not null and reply_message_bot = True and with_reply = True then 1 end) as first_response_messages_by_bot
    from messenger_response_messages t
    group by user_id, user
) _
;
