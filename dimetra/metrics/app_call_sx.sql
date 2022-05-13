create fact app_call_sx as
select
    t.event_date::date as __date__,
    t.AppCallScenario,
    t.CallType,
    t.Reciever_MicAccess,
    t.TalkDuration,
    t.cookie_id,
    t.event_date,
    t.is_receiver_init,
    t.is_receiver_ringing,
    t.user_id as user
from dma.vo_app_call_seller t
;

create metrics app_call_sx as
select
    sum(case when AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') then 1 end) as appcall_sx_any_calls,
    sum(case when AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 then 1 end) as appcall_sx_any_calls_answered,
    sum(case when AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 30 then 1 end) as appcall_sx_any_calls_success,
    sum(case when AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 and TalkDuration < 120 then 1 end) as appcall_sx_any_less120seconds,
    sum(case when AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 and TalkDuration < 15 then 1 end) as appcall_sx_any_less15seconds,
    sum(case when AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 and TalkDuration < 300 then 1 end) as appcall_sx_any_less300seconds,
    sum(case when AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 and TalkDuration < 60 then 1 end) as appcall_sx_any_less60seconds,
    sum(case when AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 then TalkDuration end) as appcall_sx_any_talkseconds,
    sum(case when CallType = 'incoming' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') then 1 end) as appcall_sx_incoming,
    sum(case when CallType = 'incoming' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 then 1 end) as appcall_sx_incoming_answered,
    sum(case when CallType = 'incoming' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'messenger_call_back', 'notification_call_back') then 1 end) as appcall_sx_incoming_callback,
    sum(case when CallType = 'incoming' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'messenger_call_back', 'notification_call_back') and TalkDuration > 0 then 1 end) as appcall_sx_incoming_callback_answered,
    sum(case when CallType = 'incoming' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'messenger_call_back', 'notification_call_back') and (TalkDuration > 0 or is_receiver_init = True or is_receiver_ringing = True) then 1 end) as appcall_sx_incoming_callback_initiated,
    sum(case when CallType = 'incoming' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'messenger_call_back', 'notification_call_back') and (TalkDuration > 0 or is_receiver_ringing = True) then 1 end) as appcall_sx_incoming_callback_ringing,
    sum(case when CallType = 'incoming' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'messenger_call_back', 'notification_call_back') and TalkDuration > 30 then 1 end) as appcall_sx_incoming_callback_success,
    sum(case when CallType = 'incoming' and AppCallScenario in ('item', 'item_gallery', 'messenger_chat_long_answer', 'messenger_chat_menu') then 1 end) as appcall_sx_incoming_direct,
    sum(case when CallType = 'incoming' and AppCallScenario in ('item', 'item_gallery', 'messenger_chat_long_answer', 'messenger_chat_menu') and TalkDuration > 0 then 1 end) as appcall_sx_incoming_direct_answered,
    sum(case when CallType = 'incoming' and AppCallScenario in ('item', 'item_gallery', 'messenger_chat_long_answer', 'messenger_chat_menu') and (TalkDuration > 0 or is_receiver_init = True or is_receiver_ringing = True) then 1 end) as appcall_sx_incoming_direct_initiated,
    sum(case when CallType = 'incoming' and AppCallScenario in ('item', 'item_gallery', 'messenger_chat_long_answer', 'messenger_chat_menu') and Reciever_MicAccess is not null then 1 end) as appcall_sx_incoming_direct_mic_checked,
    sum(case when CallType = 'incoming' and AppCallScenario in ('item', 'item_gallery', 'messenger_chat_long_answer', 'messenger_chat_menu') and Reciever_MicAccess = True then 1 end) as appcall_sx_incoming_direct_mic_granted,
    sum(case when CallType = 'incoming' and AppCallScenario in ('item', 'item_gallery', 'messenger_chat_long_answer', 'messenger_chat_menu') and (TalkDuration > 0 or is_receiver_ringing = True) then 1 end) as appcall_sx_incoming_direct_ringing,
    sum(case when CallType = 'incoming' and AppCallScenario in ('item', 'item_gallery', 'messenger_chat_long_answer', 'messenger_chat_menu') and TalkDuration > 30 then 1 end) as appcall_sx_incoming_direct_success,
    sum(case when CallType = 'incoming' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and (TalkDuration > 0 or is_receiver_init = True or is_receiver_ringing = True) then 1 end) as appcall_sx_incoming_initiated,
    sum(case when CallType = 'incoming' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 and TalkDuration < 120 then 1 end) as appcall_sx_incoming_less120seconds,
    sum(case when CallType = 'incoming' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 and TalkDuration < 15 then 1 end) as appcall_sx_incoming_less15seconds,
    sum(case when CallType = 'incoming' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 and TalkDuration < 300 then 1 end) as appcall_sx_incoming_less300seconds,
    sum(case when CallType = 'incoming' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 and TalkDuration < 60 then 1 end) as appcall_sx_incoming_less60seconds,
    sum(case when CallType = 'incoming' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and (TalkDuration > 0 or is_receiver_ringing = True) then 1 end) as appcall_sx_incoming_ringing,
    sum(case when CallType = 'incoming' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 30 then 1 end) as appcall_sx_incoming_success,
    sum(case when CallType = 'incoming' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'item', 'item_gallery', 'messenger_call_back', 'messenger_chat_long_answer', 'messenger_chat_menu', 'notification_call_back') and TalkDuration > 0 then TalkDuration end) as appcall_sx_incoming_talkseconds,
    sum(case when CallType = 'outgoing' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'messenger_call_back', 'notification_call_back') then 1 end) as appcall_sx_outgoing,
    sum(case when CallType = 'outgoing' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'messenger_call_back', 'notification_call_back') and TalkDuration > 0 then 1 end) as appcall_sx_outgoing_answered,
    sum(case when CallType = 'outgoing' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'messenger_call_back', 'notification_call_back') and TalkDuration > 30 then 1 end) as appcall_sx_outgoing_success,
    sum(case when CallType = 'outgoing' and AppCallScenario in ('call_log_callback', 'deeplink_call_back', 'messenger_call_back', 'notification_call_back') and TalkDuration > 0 then TalkDuration end) as appcall_sx_outgoing_talkseconds
from app_call_sx t
;

create metrics app_call_sx_user as
select
    sum(case when appcall_sx_incoming_direct > 0 then 1 end) as unq_appcall_sx_incoming_direct,
    sum(case when appcall_sx_incoming_direct_answered > 0 then 1 end) as unq_appcall_sx_incoming_direct_answered,
    sum(case when appcall_sx_incoming_direct_initiated > 0 then 1 end) as unq_appcall_sx_incoming_direct_initiated,
    sum(case when appcall_sx_incoming_direct_ringing > 0 then 1 end) as unq_appcall_sx_incoming_direct_ringing,
    sum(case when appcall_sx_incoming_direct_success > 0 then 1 end) as unq_appcall_sx_incoming_direct_success
from (
    select
        cookie_id, user,
        sum(case when CallType = 'incoming' and AppCallScenario in ('item', 'item_gallery', 'messenger_chat_long_answer', 'messenger_chat_menu') then 1 end) as appcall_sx_incoming_direct,
        sum(case when CallType = 'incoming' and AppCallScenario in ('item', 'item_gallery', 'messenger_chat_long_answer', 'messenger_chat_menu') and TalkDuration > 0 then 1 end) as appcall_sx_incoming_direct_answered,
        sum(case when CallType = 'incoming' and AppCallScenario in ('item', 'item_gallery', 'messenger_chat_long_answer', 'messenger_chat_menu') and (TalkDuration > 0 or is_receiver_init = True or is_receiver_ringing = True) then 1 end) as appcall_sx_incoming_direct_initiated,
        sum(case when CallType = 'incoming' and AppCallScenario in ('item', 'item_gallery', 'messenger_chat_long_answer', 'messenger_chat_menu') and (TalkDuration > 0 or is_receiver_ringing = True) then 1 end) as appcall_sx_incoming_direct_ringing,
        sum(case when CallType = 'incoming' and AppCallScenario in ('item', 'item_gallery', 'messenger_chat_long_answer', 'messenger_chat_menu') and TalkDuration > 30 then 1 end) as appcall_sx_incoming_direct_success
    from app_call_sx t
    group by cookie_id, user
) _
;
