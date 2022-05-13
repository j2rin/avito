create fact messenger_answered_messages as
select
    t.first_message_event_date as __date__,
    t.chat_subtype,
    t.first_message_cookie_id,
    t.first_message_event_date,
    t.reply_message_bot,
    t.reply_time_minutes,
    t.with_reply
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
