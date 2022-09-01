create fact app_call_event as
select
    t.event_date::date as __date__,
    *
from dma.vo_app_call_event t
;

create metrics app_call_event as
select
    sum(case when appcall_caller_end_call_rating > 0 then 1 end) as appcall_caller_end_call_feedback_count,
    sum(case when appcall_caller_end_call_rating > 0 then appcall_caller_end_call_rating end) as appcall_caller_end_call_feedback_sum,
    sum(ifnull(appcall_item_click_inapp, 0) + ifnull(appcall_item_gallery_click_inapp, 0) + ifnull(appcall_messenger_chat_long_answer_click_inapp, 0) + ifnull(appcall_messenger_chat_menu_click_inapp, 0)) as appcall_click_inapp,
    sum(case when is_iac_only = True then ifnull(appcall_item_click_inapp, 0) + ifnull(appcall_item_gallery_click_inapp, 0) + ifnull(appcall_messenger_chat_long_answer_click_inapp, 0) + ifnull(appcall_messenger_chat_menu_click_inapp, 0) end) as appcall_click_inapp_only,
    sum(ifnull(appcall_item_click_inapp, 0) + ifnull(appcall_item_gallery_click_inapp, 0) + ifnull(appcall_messenger_chat_long_answer_click_inapp, 0) + ifnull(appcall_messenger_chat_menu_click_inapp, 0) + ifnull(appcall_item_click_phone, 0) + ifnull(appcall_item_gallery_click_phone, 0) + ifnull(appcall_messenger_chat_long_answer_click_phones, 0) + ifnull(appcall_messenger_chat_menu_click_phone, 0)) as appcall_click_inapp_or_phone,
    sum(ifnull(appcall_item_click_phone, 0) + ifnull(appcall_item_gallery_click_phone, 0) + ifnull(appcall_messenger_chat_long_answer_click_phones, 0) + ifnull(appcall_messenger_chat_menu_click_phone, 0)) as appcall_click_phone,
    sum(ifnull(appcall_item_click_inapp, 0) + ifnull(appcall_item_gallery_click_inapp, 0)) as appcall_item_click_inapp,
    sum(case when is_iac_only = True then ifnull(appcall_item_click_inapp, 0) + ifnull(appcall_item_gallery_click_inapp, 0) end) as appcall_item_click_inapp_only,
    sum(ifnull(appcall_item_click_inapp, 0) + ifnull(appcall_item_gallery_click_inapp, 0) + ifnull(appcall_item_click_phone, 0) + ifnull(appcall_item_gallery_click_phone, 0)) as appcall_item_click_inapp_or_phone,
    sum(ifnull(appcall_item_click_phone, 0) + ifnull(appcall_item_gallery_click_phone, 0)) as appcall_item_click_phone,
    sum(ifnull(appcall_item_gallery_show_buttons, 0) + ifnull(appcall_item_show_buttons, 0)) as appcall_item_show_buttons,
    sum(case when is_iac_only = True then ifnull(appcall_item_gallery_show_buttons, 0) + ifnull(appcall_item_show_buttons, 0) end) as appcall_item_show_buttons_iac_only,
    sum(ifnull(appcall_item_gallery_show_buttons, 0) + ifnull(appcall_item_show_buttons, 0) + ifnull(appcall_messenger_chat_long_answer_show_buttons, 0) + ifnull(appcall_messenger_chat_menu_show_buttons, 0)) as appcall_show_buttons,
    sum(case when is_iac_only = True then ifnull(appcall_item_gallery_show_buttons, 0) + ifnull(appcall_item_show_buttons, 0) + ifnull(appcall_messenger_chat_long_answer_show_buttons, 0) + ifnull(appcall_messenger_chat_menu_show_buttons, 0) end) as appcall_show_buttons_iac_only
from app_call_event t
;

create metrics app_call_event_item as
select
    sum(case when appcall_show_buttons > 0 then 1 end) as item_appcall_show_buttons,
    sum(case when appcall_show_buttons_iac_only > 0 then 1 end) as item_appcall_show_buttons_iac_only
from (
    select
        cookie_id, item_id,
        sum(ifnull(appcall_item_gallery_show_buttons, 0) + ifnull(appcall_item_show_buttons, 0) + ifnull(appcall_messenger_chat_long_answer_show_buttons, 0) + ifnull(appcall_messenger_chat_menu_show_buttons, 0)) as appcall_show_buttons,
        sum(case when is_iac_only = True then ifnull(appcall_item_gallery_show_buttons, 0) + ifnull(appcall_item_show_buttons, 0) + ifnull(appcall_messenger_chat_long_answer_show_buttons, 0) + ifnull(appcall_messenger_chat_menu_show_buttons, 0) end) as appcall_show_buttons_iac_only
    from app_call_event t
    group by cookie_id, item_id
) _
;

create metrics app_call_event_user as
select
    sum(case when appcall_click_inapp > 0 then 1 end) as user_appcall_click_inapp,
    sum(case when appcall_click_inapp_only > 0 then 1 end) as user_appcall_click_inapp_only,
    sum(case when appcall_item_click_inapp_or_phone > 0 then 1 end) as user_appcall_click_inapp_or_phone,
    sum(case when appcall_click_phone > 0 then 1 end) as user_appcall_click_phone,
    sum(case when appcall_show_buttons > 0 then 1 end) as user_appcall_show_buttons,
    sum(case when appcall_show_buttons_iac_only > 0 then 1 end) as user_appcall_show_buttons_iac_only
from (
    select
        cookie_id, user_id,
        sum(ifnull(appcall_item_click_inapp, 0) + ifnull(appcall_item_gallery_click_inapp, 0) + ifnull(appcall_messenger_chat_long_answer_click_inapp, 0) + ifnull(appcall_messenger_chat_menu_click_inapp, 0)) as appcall_click_inapp,
        sum(case when is_iac_only = True then ifnull(appcall_item_click_inapp, 0) + ifnull(appcall_item_gallery_click_inapp, 0) + ifnull(appcall_messenger_chat_long_answer_click_inapp, 0) + ifnull(appcall_messenger_chat_menu_click_inapp, 0) end) as appcall_click_inapp_only,
        sum(ifnull(appcall_item_click_phone, 0) + ifnull(appcall_item_gallery_click_phone, 0) + ifnull(appcall_messenger_chat_long_answer_click_phones, 0) + ifnull(appcall_messenger_chat_menu_click_phone, 0)) as appcall_click_phone,
        sum(ifnull(appcall_item_click_inapp, 0) + ifnull(appcall_item_gallery_click_inapp, 0) + ifnull(appcall_item_click_phone, 0) + ifnull(appcall_item_gallery_click_phone, 0)) as appcall_item_click_inapp_or_phone,
        sum(ifnull(appcall_item_gallery_show_buttons, 0) + ifnull(appcall_item_show_buttons, 0) + ifnull(appcall_messenger_chat_long_answer_show_buttons, 0) + ifnull(appcall_messenger_chat_menu_show_buttons, 0)) as appcall_show_buttons,
        sum(case when is_iac_only = True then ifnull(appcall_item_gallery_show_buttons, 0) + ifnull(appcall_item_show_buttons, 0) + ifnull(appcall_messenger_chat_long_answer_show_buttons, 0) + ifnull(appcall_messenger_chat_menu_show_buttons, 0) end) as appcall_show_buttons_iac_only
    from app_call_event t
    group by cookie_id, user_id
) _
;
