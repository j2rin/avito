create fact messenger_stream as
select
    t.event_date::date as __date__,
    *
from dma.vo_messenger_stream t
;

create metrics messenger_stream as
select
    sum(case when eid = 3109 then event_count end) as attach_button_clicks,
    sum(case when eid = 2920 then event_count end) as chat_list_views,
    sum(case when eid = 3324 then event_count end) as chat_open_errors,
    sum(case when eid = 2919 then event_count end) as chat_views,
    sum(case when eid = 2722 then event_count end) as close_offer_closes,
    sum(case when eid = 2724 then event_count end) as close_offer_shows,
    sum(case when eid in (2919, 2920) then event_count end) as cnt_chat_list_views,
    sum(case when eid = 3110 then event_count end) as geo_button_clicks,
    sum(case when eid = 3130 then event_count end) as item_views_from_messenger,
    sum(case when eid = 313 and action_type_id = 1 then event_count end) as items_closed_from_messenger,
    sum(case when eid = 313 and action_type_id = 1 and report_reason = '22' then event_count end) as items_sold_onavito_from_messenger,
    sum(case when eid = 3129 then event_count end) as message_start_writing,
    sum(case when eid = 3176 and message_type = 'geo' and source = 'mini_messenger' then event_count end) as mini_m_geo_send_button_clicks,
    sum(case when eid = 3176 and message_type = 'image' and source = 'mini_messenger' then event_count end) as mini_m_image_send_button_clicks,
    sum(case when eid = 3176 and message_type = 'item' and source = 'mini_messenger' then event_count end) as mini_m_item_send_button_clicks,
    sum(case when eid = 3176 and message_type = 'text' and source = 'mini_messenger' then event_count end) as mini_m_text_send_button_clicks,
    sum(case when eid = 2998 then event_count end) as profile_views_from_messenger,
    sum(case when eid = 3177 then event_count end) as retry_button_clicks,
    sum(case when eid = 3176 and message_type = 'geo' then event_count end) as total_geo_send_button_clicks,
    sum(case when eid = 3176 and message_type = 'image' then event_count end) as total_image_send_button_clicks,
    sum(case when eid = 3176 and message_type = 'item' then event_count end) as total_item_send_button_clicks,
    sum(case when eid = 3176 then event_count end) as total_send_button_clicks,
    sum(case when eid = 3176 and message_type = 'text' then event_count end) as total_text_send_button_clicks
from messenger_stream t
;

create metrics messenger_stream_cookie_id as
select
    sum(case when cnt_chat_list_views > 0 then 1 end) as messenger_visitors
from (
    select
        user_id, cookie_id,
        sum(case when eid in (2919, 2920) then event_count end) as cnt_chat_list_views
    from messenger_stream t
    group by user_id, cookie_id
) _
;

create metrics messenger_stream_user_id as
select
    sum(case when chat_open_errors > 0 then 1 end) as users_chat_open_errors,
    sum(case when items_closed_from_messenger > 0 then 1 end) as users_item_closed_from_messenger,
    sum(case when items_sold_onavito_from_messenger > 0 then 1 end) as users_item_sold_onavito_from_messenger
from (
    select
        user_id,
        sum(case when eid = 3324 then event_count end) as chat_open_errors,
        sum(case when eid = 313 and action_type_id = 1 then event_count end) as items_closed_from_messenger,
        sum(case when eid = 313 and action_type_id = 1 and report_reason = '22' then event_count end) as items_sold_onavito_from_messenger
    from messenger_stream t
    group by user_id
) _
;
