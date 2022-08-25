create fact support_chat as
select
    t.create_date::date as __date__,
    *
from dma.vo_support_chat t
;

create metrics support_chat as
select
    sum(1) as chats_created
from support_chat t
;

create metrics support_chat_user_id as
select
    sum(case when chats_created > 0 then 1 end) as users_with_chats
from (
    select
        user_id,
        sum(1) as chats_created
    from support_chat t
    group by user_id
) _
;
