create fact support_ticket as
select
    t.create_date::date as __date__,
    *
from dma.vo_support_ticket t
;

create metrics support_ticket as
select
    sum(helpdesk_seller_tickets) as helpdesk_seller_tickets,
    sum(case when is_normal = True and by_amuser = False and satisfaction_score >= 4 then 1 end) as high_scored_tickets,
    sum(case when is_normal = True and by_amuser = False and satisfaction_score = 1 then 1 end) as low_scored_tickets,
    sum(case when is_normal = True and by_amuser = False and satisfaction_score is not null then 1 end) as scored_tickets,
    sum(case when is_normal = True and by_amuser = False then 1 end) as tickets_created_big10,
    sum(case when is_normal = True and by_amuser = False and hours_to_reply < 48 then 1 end) as tickets_created_big10_less48,
    sum(case when is_normal = True and by_amuser = False and hours_to_reply < 48 then hours_to_reply end) as tickets_hours_to_reply_less48
from support_ticket t
;

create metrics support_ticket_user_id as
select
    sum(case when tickets_created_big10 > 0 then 1 end) as users_with_created_tickets,
    sum(case when helpdesk_seller_tickets > 0 then 1 end) as users_with_helpdesk_tickets
from (
    select
        user_id,
        sum(helpdesk_seller_tickets) as helpdesk_seller_tickets,
        sum(case when is_normal = True and by_amuser = False then 1 end) as tickets_created_big10
    from support_ticket t
    group by user_id
) _
;
