create fact messenger_response_messages as
select
    t.reply_time::date as __date__,
    *
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
        user_id,
        sum(case when chat_subtype is null and with_reply = True then 1 end) as first_response_messages,
        sum(case when item_id is not null and reply_message_bot = True and with_reply = True then 1 end) as first_response_messages_by_bot
    from messenger_response_messages t
    group by user_id
) _
;
