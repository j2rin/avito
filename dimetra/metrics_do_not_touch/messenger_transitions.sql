create fact messenger_transitions as
select
    t.trigger_date::date as __date__,
    *
from dma.vo_messenger_transitions t
;

create metrics messenger_transitions as
select
    sum(1) as messenger_transitions,
    sum(case when trigger = 'messenger' then 1 end) as messenger_transitions_another_messenger,
    sum(case when trigger = 'messenger' and is_abandoned_chat = True then 1 end) as messenger_transitions_another_messenger_abandoned_chat,
    sum(case when trigger = 'messenger' and chat_role = 'buyer' then 1 end) as messenger_transitions_another_messenger_buyer,
    sum(case when trigger = 'messenger' and chat_role = 'seller' then 1 end) as messenger_transitions_another_messenger_seller,
    sum(case when chat_role = 'buyer' then 1 end) as messenger_transitions_buyer,
    sum(case when is_copy_after_trigger = True then 1 end) as messenger_transitions_copy,
    sum(case when trigger = 'email' then 1 end) as messenger_transitions_email,
    sum(case when is_first_message = True then 1 end) as messenger_transitions_first_msg,
    sum(case when trigger = 'link' then 1 end) as messenger_transitions_link,
    sum(case when trigger = 'phone' then 1 end) as messenger_transitions_phone,
    sum(case when trigger = 'phone' and is_abandoned_chat = True then 1 end) as messenger_transitions_phone_abandoned_chat,
    sum(case when chat_role = 'seller' then 1 end) as messenger_transitions_seller
from messenger_transitions t
;

create metrics messenger_transitions_user as
select
    sum(case when messenger_transitions > 0 then 1 end) as user_messenger_transitions,
    sum(case when messenger_transitions_another_messenger > 0 then 1 end) as user_messenger_transitions_another_messenger,
    sum(case when messenger_transitions_another_messenger_buyer > 0 then 1 end) as user_messenger_transitions_another_messenger_buyer,
    sum(case when messenger_transitions_another_messenger_seller > 0 then 1 end) as user_messenger_transitions_another_messenger_seller,
    sum(case when messenger_transitions_buyer > 0 then 1 end) as user_messenger_transitions_buyer,
    sum(case when messenger_transitions_email > 0 then 1 end) as user_messenger_transitions_email,
    sum(case when messenger_transitions_link > 0 then 1 end) as user_messenger_transitions_link,
    sum(case when messenger_transitions_phone > 0 then 1 end) as user_messenger_transitions_phone,
    sum(case when messenger_transitions_seller > 0 then 1 end) as user_messenger_transitions_seller
from (
    select
        user_id,
        sum(1) as messenger_transitions,
        sum(case when trigger = 'messenger' then 1 end) as messenger_transitions_another_messenger,
        sum(case when trigger = 'messenger' and chat_role = 'buyer' then 1 end) as messenger_transitions_another_messenger_buyer,
        sum(case when trigger = 'messenger' and chat_role = 'seller' then 1 end) as messenger_transitions_another_messenger_seller,
        sum(case when chat_role = 'buyer' then 1 end) as messenger_transitions_buyer,
        sum(case when trigger = 'email' then 1 end) as messenger_transitions_email,
        sum(case when trigger = 'link' then 1 end) as messenger_transitions_link,
        sum(case when trigger = 'phone' then 1 end) as messenger_transitions_phone,
        sum(case when chat_role = 'seller' then 1 end) as messenger_transitions_seller
    from messenger_transitions t
    group by user_id
) _
;
