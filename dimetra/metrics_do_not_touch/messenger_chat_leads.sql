create fact messenger_chat_leads as
select
    t.first_message_event_date::date as __date__,
    *
from dma.vo_chat_scores t
;

create metrics messenger_chat_leads as
select
    sum(case when class in (0) then 1 end) as chat_first_class,
    sum(case when class in (0.25) then 1 end) as chat_second_class,
    sum(case when sum_probability <= 0.15 then 1 end) as no_target_chat,
    sum(case when sum_probability >= 0.5 then 1 end) as target_contact_chat,
    sum(case when class in (0.5, 0.75, 1.0) then 1 end) as target_contact_chat_class,
    sum(case when sum_probability >= 0.35 then 1 end) as target_contact_chat_prob35
from messenger_chat_leads t
;

create metrics messenger_chat_leads_user as
select
    sum(case when target_contact_chat > 0 then 1 end) as user_target_contact_chat,
    sum(case when target_contact_chat_class > 0 then 1 end) as user_target_contact_chat_class,
    sum(case when target_contact_chat_prob35 > 0 then 1 end) as user_target_contact_chat_prob35
from (
    select
        user_id,
        sum(case when sum_probability >= 0.5 then 1 end) as target_contact_chat,
        sum(case when class in (0.5, 0.75, 1.0) then 1 end) as target_contact_chat_class,
        sum(case when sum_probability >= 0.35 then 1 end) as target_contact_chat_prob35
    from messenger_chat_leads t
    group by user_id
) _
;
