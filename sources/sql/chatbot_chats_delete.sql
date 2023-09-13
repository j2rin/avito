select
    t.user_id,
    cast(delete_date as date) as event_date,
    chat_type,
    cnt_deletes
from  DMA.chatbot_chats_delete t
where user_id not in (select user_id from dma."current_user" where isTest)
    and cast(delete_date as date) between :first_date and :last_date
