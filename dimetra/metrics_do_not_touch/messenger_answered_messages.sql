create fact messenger_answered_messages as
select
    t.first_message_event_date::date as __date__,
    *
from dma.vo_messenger_chat_report t
;

create metrics messenger_answered_messages as
select
    sum(case when chat_subtype is null and with_reply = True and reply_message_bot is null and reply_time_minutes <= 4320 and reply_time_minutes >= 0 then 1 end) as answered_first_messages,
    sum(case when chat_subtype is null and with_reply = True and reply_message_bot is null and reply_time_minutes <= 60 and reply_time_minutes >= 0 then 1 end) as answered_first_messages_1hour,
    sum(case when chat_subtype is null and with_reply = True and reply_message_bot = True and reply_time_minutes <= 4320 and reply_time_minutes >= 0 then 1 end) as answered_first_messages_by_bot,
    sum(case when chat_subtype is null and reply_message_bot is null and with_reply = True and reply_time_minutes >= 0 and reply_time_minutes <= 1440 then 1 end) as answered_first_messages_within_1day,
    sum(case when chat_subtype is null and with_reply = True and reply_message_bot is null and reply_time_minutes <= 420 and reply_time_minutes > 60 then 1 end) as answered_first_messages_within_1hour_7hour
from messenger_answered_messages t
;

create metrics messenger_answered_messages_first_message_cookie_id as
select
    sum(case when answered_first_messages > 0 then 1 end) as user_answered_first_messages
from (
    select
        first_message_cookie_id,
        sum(case when chat_subtype is null and with_reply = True and reply_message_bot is null and reply_time_minutes <= 4320 and reply_time_minutes >= 0 then 1 end) as answered_first_messages
    from messenger_answered_messages t
    group by first_message_cookie_id
) _
;
