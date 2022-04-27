create fact messenger_inbox_messages as
select
    t.chat_subtype,
    t.chat_type,
    t.first_message_event_date,
    t.item_id,
    t.user_id
from dma.vo_messenger_chat_report t
;

create metrics messenger_inbox_messages as
select
    sum(case when item_id is not null and chat_subtype is null then 1 end) as inbox_first_messages,
    sum(case when chat_type = 'u2u' then 1 end) as inbox_first_messages_u2u
from messenger_inbox_messages t
;