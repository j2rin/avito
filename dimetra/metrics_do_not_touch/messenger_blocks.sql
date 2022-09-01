create fact messenger_blocks as
select
    t.event_date::date as __date__,
    *
from dma.vo_messenger_blocks t
;

create metrics messenger_blocks as
select
    sum(case when is_first_block = True and is_item_owner = True then 1 end) as cnt_messenger_spam_blocks,
    sum(case when is_first_block = True then 1 end) as cnt_messenger_users_blocked
from messenger_blocks t
;

create metrics messenger_blocks_chat as
select
    sum(case when cnt_messenger_spam_blocks > 0 then 1 end) as messenger_spam_blocks,
    sum(case when cnt_messenger_users_blocked > 0 then 1 end) as messenger_users_blocked
from (
    select
        user_id, chat_Id,
        sum(case when is_first_block = True and is_item_owner = True then 1 end) as cnt_messenger_spam_blocks,
        sum(case when is_first_block = True then 1 end) as cnt_messenger_users_blocked
    from messenger_blocks t
    group by user_id, chat_Id
) _
;
