create fact messenger_inbox_chat_leads as
select
    t.first_message_event_date::date as __date__,
    *
from dma.vo_chat_scores t
;

create metrics messenger_inbox_chat_leads as
select
    sum(case when class in (0.5, 0.75, 1.0) then 1 end) as target_contact_chat_class_inbox,
    sum(case when sum_probability >= 0.5 then 1 end) as target_contact_chat_inbox,
    sum(case when sum_probability >= 0.35 then 1 end) as target_contact_chat_prob35_inbox
from messenger_inbox_chat_leads t
;

create metrics messenger_inbox_chat_leads_user as
select
    sum(case when target_contact_chat_class_inbox > 0 then 1 end) as user_target_contact_chat_class_inbox,
    sum(case when target_contact_chat_inbox > 0 then 1 end) as user_target_contact_chat_inbox,
    sum(case when target_contact_chat_prob35_inbox > 0 then 1 end) as user_target_contact_chat_prob35_inbox
from (
    select
        seller_id,
        sum(case when class in (0.5, 0.75, 1.0) then 1 end) as target_contact_chat_class_inbox,
        sum(case when sum_probability >= 0.5 then 1 end) as target_contact_chat_inbox,
        sum(case when sum_probability >= 0.35 then 1 end) as target_contact_chat_prob35_inbox
    from messenger_inbox_chat_leads t
    group by seller_id
) _
;
