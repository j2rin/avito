create fact app_call_bx as
select
    t.AppCallScenario,
    t.CallType,
    t.TalkDuration,
    t.cookie_id,
    t.event_date,
    t.user_id as user
from dma.vo_app_call_buyer t
;

create metrics app_call_bx as
select
    sum(case when AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') then 1 end) as appcall_bx_any_calls,
    sum(case when AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 then 1 end) as appcall_bx_any_calls_answered,
    sum(case when AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 30 then 1 end) as appcall_bx_any_calls_success,
    sum(case when AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 and TalkDuration < 120 then 1 end) as appcall_bx_any_less120seconds,
    sum(case when AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 and TalkDuration < 15 then 1 end) as appcall_bx_any_less15seconds,
    sum(case when AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 and TalkDuration < 300 then 1 end) as appcall_bx_any_less300seconds,
    sum(case when AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 and TalkDuration < 60 then 1 end) as appcall_bx_any_less60seconds,
    sum(case when AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 then TalkDuration end) as appcall_bx_any_talkseconds,
    sum(case when CallType = 'incoming' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'messenger_call_back', 'notification_call_back') then 1 end) as appcall_bx_incoming,
    sum(case when CallType = 'incoming' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'messenger_call_back', 'notification_call_back') and TalkDuration > 0 then 1 end) as appcall_bx_incoming_answered,
    sum(case when CallType = 'incoming' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'messenger_call_back', 'notification_call_back') and TalkDuration > 30 then 1 end) as appcall_bx_incoming_success,
    sum(case when CallType = 'incoming' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'messenger_call_back', 'notification_call_back') and TalkDuration > 0 then TalkDuration end) as appcall_bx_incoming_talkseconds,
    sum(case when CallType = 'outgoing' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') then 1 end) as appcall_bx_outgoing,
    sum(case when CallType = 'outgoing' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 then 1 end) as appcall_bx_outgoing_answered,
    sum(case when CallType = 'outgoing' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'messenger_call_back', 'notification_call_back') then 1 end) as appcall_bx_outgoing_callback,
    sum(case when CallType = 'outgoing' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'messenger_call_back', 'notification_call_back') and TalkDuration > 0 then 1 end) as appcall_bx_outgoing_callback_answered,
    sum(case when CallType = 'outgoing' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'messenger_call_back', 'notification_call_back') and TalkDuration > 30 then 1 end) as appcall_bx_outgoing_callback_success,
    sum(case when CallType = 'outgoing' and AppCallScenario in ('item', 'item_gallery', 'messenger_chat_long_answer', 'messenger_chat_menu') then 1 end) as appcall_bx_outgoing_direct,
    sum(case when CallType = 'outgoing' and AppCallScenario in ('item', 'item_gallery', 'messenger_chat_long_answer', 'messenger_chat_menu') and TalkDuration > 0 then 1 end) as appcall_bx_outgoing_direct_answered,
    sum(case when CallType = 'outgoing' and AppCallScenario in ('item', 'item_gallery', 'messenger_chat_long_answer', 'messenger_chat_menu') and TalkDuration > 30 then 1 end) as appcall_bx_outgoing_direct_success,
    sum(case when CallType = 'outgoing' and AppCallScenario in ('item', 'item_gallery') then 1 end) as appcall_bx_outgoing_item,
    sum(case when CallType = 'outgoing' and AppCallScenario in ('item', 'item_gallery') and TalkDuration > 0 then 1 end) as appcall_bx_outgoing_item_answered,
    sum(case when CallType = 'outgoing' and AppCallScenario in ('item', 'item_gallery') and TalkDuration > 30 then 1 end) as appcall_bx_outgoing_item_success,
    sum(case when CallType = 'outgoing' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 and TalkDuration < 120 then 1 end) as appcall_bx_outgoing_less120seconds,
    sum(case when CallType = 'outgoing' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 and TalkDuration < 15 then 1 end) as appcall_bx_outgoing_less15seconds,
    sum(case when CallType = 'outgoing' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 and TalkDuration < 300 then 1 end) as appcall_bx_outgoing_less300seconds,
    sum(case when CallType = 'outgoing' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 and TalkDuration < 60 then 1 end) as appcall_bx_outgoing_less60seconds,
    sum(case when CallType = 'outgoing' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 30 then 1 end) as appcall_bx_outgoing_success,
    sum(case when CallType = 'outgoing' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 then TalkDuration end) as appcall_bx_outgoing_talkseconds
from app_call_bx t
;

create metrics app_call_bx_user as
select
    sum(case when appcall_bx_outgoing_item > 0 then 1 end) as unq_appcall_bx_outgoing_item,
    sum(case when appcall_bx_outgoing_item_success > 0 then 1 end) as unq_appcall_bx_outgoing_item_success
from (
    select
        cookie_id, user,
        sum(case when CallType = 'outgoing' and AppCallScenario in ('item', 'item_gallery') then 1 end) as appcall_bx_outgoing_item,
        sum(case when CallType = 'outgoing' and AppCallScenario in ('item', 'item_gallery') and TalkDuration > 30 then 1 end) as appcall_bx_outgoing_item_success
    from app_call_bx t
    group by cookie_id, user
) _
;
