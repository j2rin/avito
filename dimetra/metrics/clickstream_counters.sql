create fact clickstream_counters as
select
    t.event_date::date as __date__,
    t.action_type,
    t.app_call_mic_access,
    t.banner_id,
    t.cookie_id as cookie,
    t.cookie_id,
    t.eid,
    t.event_count,
    t.event_date,
    t.ext_profile_is_using,
    t.fps_threshold,
    t.from_block,
    t.from_page,
    t.is_delivery_available,
    t.is_notifications_on,
    t.item_id,
    t.network_error_sub_type,
    t.network_error_type,
    t.notification_value,
    t.page_type,
    t.placement,
    t.profile_type,
    t.search_correction_action,
    t.search_correction_method,
    t.source
from dma.vo_clickstream_counters t
;

create metrics clickstream_counters as
select
    sum(case when eid = 2908 and source = 'favorite_sellers' then event_count end) as buyer_favouriteseller_add_from_fs,
    sum(case when eid = 2908 and source = 'public_profile' then event_count end) as buyer_favouriteseller_add_from_pp,
    sum(case when eid = 2908 and source = 'shop_page' then event_count end) as buyer_favouriteseller_add_from_shop,
    sum(case when eid = 2908 and source = 'subscribers_list' then event_count end) as buyer_favouriteseller_add_from_subscribers_list,
    sum(case when eid = 2908 and source = 'subscriptions_list' then event_count end) as buyer_favouriteseller_add_from_subscriptions_list,
    sum(case when eid = 2909 and source = 'favorite_sellers' then event_count end) as buyer_favouriteseller_delete_from_fs,
    sum(case when eid = 2909 and source = 'public_profile' then event_count end) as buyer_favouriteseller_delete_from_pp,
    sum(case when eid = 2909 and source = 'shop_page' then event_count end) as buyer_favouriteseller_delete_from_shop,
    sum(case when eid = 2909 and source = 'subscribers_list' then event_count end) as buyer_favouriteseller_delete_from_subscribers_list,
    sum(case when eid = 2909 and source = 'subscriptions_list' then event_count end) as buyer_favouriteseller_delete_from_subscriptions_list,
    sum(case when eid = 3381 and from_block is null then event_count end) as call_phone_screen_views_client,
    sum(case when eid = 3207 and placement = 'splash.banner' and page_type = 'main' and banner_id = 'child' and action_type = 'click-positive' then event_count end) as click_banner_download_app,
    sum(case when eid = 3207 and banner_id ilike '%mygarage%' then event_count end) as click_banner_mygarage,
    sum(case when eid = 4921 and from_page = 'vertical_category' then event_count end) as click_category_widget,
    sum(case when eid = 4921 and from_page = 'featured' then event_count end) as click_featured_widget,
    sum(case when eid = 4921 and from_page = 'vertical_promo' then event_count end) as click_promo_widget,
    sum(case when eid = 4921 and from_page = 'recentSearch' then event_count end) as click_recent_search_widget,
    sum(case when eid = 4921 and from_page = 'vertical_recommendations' then event_count end) as click_recommendations_widget,
    sum(case when eid = 4954 then event_count end) as click_search_widget,
    sum(case when eid = 5070 and ext_profile_is_using is null then event_count end) as ext_profile_off,
    sum(case when eid = 5070 and ext_profile_is_using = True then event_count end) as ext_profile_on,
    sum(case when eid = 3187 and source = 'favourites' then event_count end) as fav_add_from_fav,
    sum(case when eid = 3187 and source = 'item' then event_count end) as fav_add_from_iv,
    sum(case when eid = 3187 and source = 'snippet' then event_count end) as fav_add_from_serp,
    sum(case when eid = 2908 then event_count end) as favouriteseller_adds,
    sum(case when eid = 2909 then event_count end) as favouriteseller_deletes,
    sum(case when eid = 5243 and fps_threshold = 10 then event_count end) as fps_falls_below_10pct,
    sum(case when eid = 5243 and fps_threshold = 30 then event_count end) as fps_falls_below_30pct,
    sum(case when eid = 5243 and fps_threshold = 50 then event_count end) as fps_falls_below_50pct,
    sum(case when eid = 5243 and fps_threshold = 70 then event_count end) as fps_falls_below_70pct,
    sum(case when eid = 5243 and fps_threshold = 85 then event_count end) as fps_falls_below_85pct,
    sum(case when eid = 5243 and fps_threshold = 90 then event_count end) as fps_falls_below_90pct,
    sum(case when eid = 5243 and fps_threshold = 95 then event_count end) as fps_falls_below_95pct,
    sum(case when eid = 3020 and search_correction_method = 'geo_redirect' then event_count end) as geo_redirect_disabled,
    sum(case when eid = 3019 and search_correction_method = 'geo_redirect' and search_correction_action = 'replace' then event_count end) as geo_redirect_replace,
    sum(case when eid = 3019 and search_correction_method = 'geo_redirect' and search_correction_action = 'suggest' then event_count end) as geo_redirect_suggest,
    sum(case when eid = 3020 and search_correction_method = 'geo_redirect_suggest' then event_count end) as geo_redirect_suggest_disabled,
    sum(case when eid = 4210 and (source is null or source = 'item') then event_count end) as icebreakers_message_template_clicks,
    sum(case when eid = 4210 and (source in ('messenger', 'mini-messenger')) then event_count end) as icebreakers_message_template_clicks_msg,
    sum(case when eid = 4209 and (source is null or source = 'item') then event_count end) as icebreakers_message_template_shows,
    sum(case when eid = 4209 and (source in ('messenger', 'mini-messenger')) then event_count end) as icebreakers_message_template_shows_msg,
    sum(case when eid = 3020 and search_correction_method = 'keyboard' then event_count end) as keyboard_disabled,
    sum(case when eid = 3019 and search_correction_method = 'keyboard' and search_correction_action = 'replace' then event_count end) as keyboard_replace,
    sum(case when eid = 3019 and search_correction_method = 'keyboard' and search_correction_action = 'suggest' then event_count end) as keyboard_suggest,
    sum(case when eid = 3020 and search_correction_method = 'keyboard_suggest' then event_count end) as keyboard_suggest_disabled,
    sum(case when eid = 4100 and app_call_mic_access = False then event_count end) as mic_access_denied,
    sum(case when eid = 4100 and app_call_mic_access = True then event_count end) as mic_access_granted,
    sum(case when eid = 3020 and search_correction_method = 'misspell' then event_count end) as misspell_disabled,
    sum(case when eid = 3019 and search_correction_method = 'misspell' and search_correction_action = 'replace' then event_count end) as misspell_replace,
    sum(case when eid = 3019 and search_correction_method = 'misspell' and search_correction_action = 'suggest' then event_count end) as misspell_suggest,
    sum(case when eid = 3020 and search_correction_method = 'misspell_suggest' then event_count end) as misspell_suggest_disabled,
    sum(case when eid = 4599 and network_error_type = 'network system error' and network_error_sub_type = 'bad request' then event_count end) as network_api_bad_request_error,
    sum(case when eid = 4599 and network_error_type = 'api error' then event_count end) as network_api_error,
    sum(case when eid = 4599 and network_error_type = '2. backend error' then event_count end) as network_backend_error,
    sum(case when eid = 4599 and network_error_type = 'network client error' then event_count end) as network_client_error,
    sum(case when eid = 4599 and network_error_type = '2. client error' then event_count end) as network_client_error2,
    sum(case when eid = 4599 and network_error_type = 'network client error' and network_error_sub_type = 'attempt to send authorized request with no session' then event_count end) as network_client_no_session_error,
    sum(case when eid = 4599 and network_error_type = 'network client error' and network_error_sub_type = 'parsing failure' then event_count end) as network_client_parsing_error,
    sum(case when eid = 4599 then event_count end) as network_error,
    sum(case when eid = 4599 and network_error_type = 'forbidden' then event_count end) as network_forbidden_error,
    sum(case when eid = 4599 and network_error_type in ('2. image error', 'image load error') then event_count end) as network_image_load_error,
    sum(case when eid = 4599 and network_error_type = '2. network error' then event_count end) as network_network_error,
    sum(case when eid = 4599 and network_error_type = 'network system error' then event_count end) as network_system_error,
    sum(case when eid = 4599 and network_error_type = 'http unauthenticated' then event_count end) as network_unauthenticated_error,
    sum(case when eid = 4599 and network_error_type = '2. upload error' then event_count end) as network_upload_error,
    sum(case when eid = 2582 and action_type = 'create' then event_count end) as notes_create,
    sum(case when eid = 2582 and action_type = 'delete' then event_count end) as notes_delete,
    sum(case when eid = 2582 and action_type = 'update' then event_count end) as notes_update,
    sum(case when (eid = 2558 and is_notifications_on = False or eid = 2390 and notification_value = False) then event_count end) as notifications_off_any,
    sum(case when eid = 2390 and notification_value = False then event_count end) as notifications_off_profile,
    sum(case when eid = 2558 and is_notifications_on = False then event_count end) as notifications_off_system,
    sum(case when (eid = 2558 and is_notifications_on = True or eid = 2390 and notification_value = True) then event_count end) as notifications_on_any,
    sum(case when eid = 2390 and notification_value = True then event_count end) as notifications_on_profile,
    sum(case when eid = 2558 and is_notifications_on = True then event_count end) as notifications_on_system,
    sum(case when eid in (2016, 3060) then event_count end) as profile_shop_views,
    sum(case when eid = 2016 then event_count end) as profile_views_any,
    sum(case when eid = 2016 and profile_type = 'extended_profile' then event_count end) as profile_views_extended,
    sum(case when eid = 2016 and profile_type = 'public_profile' then event_count end) as profile_views_public,
    sum(case when eid = 2016 and source = 'fs' then event_count end) as public_profile_visit_from_fs,
    sum(case when eid = 2016 and source = 'item' then event_count end) as public_profile_visit_from_item,
    sum(case when eid = 2016 and source = 'subscribers_list' then event_count end) as public_profile_visit_from_subscribers_list,
    sum(case when eid = 2016 and source = 'messenger' then event_count end) as public_profile_visit_from_subscribers_messenger,
    sum(case when eid = 2016 and source = 'subscriptions_list' then event_count end) as public_profile_visit_from_subscriptions_list,
    sum(case when eid = 2016 and source = 'ratings' then event_count end) as public_profile_visit_from_subscriptions_ratings,
    sum(case when eid = 2016 and source = 'sharing' then event_count end) as public_profile_visit_from_subscriptions_sharing,
    sum(case when eid = 3207 and placement = 'splash.banner' and page_type = 'main' and banner_id = 'child' and action_type = 'click-negative' then event_count end) as reject_banner_download_app,
    sum(case when eid = 3020 then event_count end) as search_corrections_disabled,
    sum(case when eid = 3019 then event_count end) as search_query_corrections,
    sum(case when eid = 3020 and search_correction_method = 'search_redirect' then event_count end) as search_redirect_disabled,
    sum(case when eid = 3019 and search_correction_method = 'search_redirect' and search_correction_action = 'replace' then event_count end) as search_redirect_replace,
    sum(case when eid = 3019 and search_correction_method = 'search_redirect' and search_correction_action = 'suggest' then event_count end) as search_redirect_suggest,
    sum(case when eid = 3020 and search_correction_method = 'search_redirect_suggest' then event_count end) as search_redirect_suggest_disabled,
    sum(case when eid = 3060 then event_count end) as shop_views,
    sum(case when eid = 3180 and placement = 'splash.banner' and page_type = 'main' and banner_id = 'child' then event_count end) as show_banner_download_app,
    sum(case when eid = 3180 and banner_id ilike '%mygarage%' then event_count end) as show_banner_mygarage,
    sum(case when eid = 4920 and from_page = 'vertical_category' then event_count end) as show_category_widget,
    sum(case when eid = 4920 and from_page = 'featured' then event_count end) as show_featured_widget,
    sum(case when eid = 4920 and from_page = 'vertical_promo' then event_count end) as show_promo_widget,
    sum(case when eid = 4920 and from_page = 'recentSearch' then event_count end) as show_recent_search_widget,
    sum(case when eid = 4920 and from_page = 'vertical_recommendations' then event_count end) as show_recommendations_widget,
    sum(case when eid = 4920 and from_page = 'vertical_filter' then event_count end) as show_search_widget,
    sum(case when eid = 3020 and search_correction_method = 'sqp_layout' then event_count end) as sqp_layout_disabled,
    sum(case when eid = 3019 and search_correction_method = 'sqp_layout' and search_correction_action = 'replace' then event_count end) as sqp_layout_replace,
    sum(case when eid = 3019 and search_correction_method = 'sqp_layout' and search_correction_action = 'suggest' then event_count end) as sqp_layout_suggest,
    sum(case when eid = 3020 and search_correction_method = 'sqp_layout_suggest' then event_count end) as sqp_layout_suggest_disabled,
    sum(case when eid = 3020 and search_correction_method = 'sqp_wordbreaker_digit' then event_count end) as sqp_wordbreaker_digit_disabled,
    sum(case when eid = 3019 and search_correction_method = 'sqp_wordbreaker_digit' and search_correction_action = 'replace' then event_count end) as sqp_wordbreaker_digit_replace,
    sum(case when eid = 3019 and search_correction_method = 'sqp_wordbreaker_digit' and search_correction_action = 'suggest' then event_count end) as sqp_wordbreaker_digit_suggest,
    sum(case when eid = 3020 and search_correction_method = 'sqp_wordbreaker_digit_suggest' then event_count end) as sqp_wordbreaker_digit_suggest_disabled,
    sum(case when eid = 3020 and search_correction_method = 'sqp_wordbreaker' then event_count end) as sqp_wordbreaker_disabled,
    sum(case when eid = 3019 and search_correction_method = 'sqp_wordbreaker' and search_correction_action = 'replace' then event_count end) as sqp_wordbreaker_replace,
    sum(case when eid = 3019 and search_correction_method = 'sqp_wordbreaker' and search_correction_action = 'suggest' then event_count end) as sqp_wordbreaker_suggest,
    sum(case when eid = 3020 and search_correction_method = 'sqp_wordbreaker_suggest' then event_count end) as sqp_wordbreaker_suggest_disabled,
    sum(case when eid = 3020 and search_correction_method = 'teleport' then event_count end) as teleport_disabled,
    sum(case when eid = 3019 and search_correction_method = 'teleport' and search_correction_action = 'replace' then event_count end) as teleport_replace,
    sum(case when eid = 3019 and search_correction_method = 'teleport' and search_correction_action = 'suggest' then event_count end) as teleport_suggest,
    sum(case when eid = 3020 and search_correction_method = 'teleport_suggest' then event_count end) as teleport_suggest_disabled,
    sum(case when eid = 2703 and is_delivery_available = False then event_count end) as total_item_off_delivery,
    sum(case when eid = 2703 and is_delivery_available = True then event_count end) as total_item_on_delivery,
    sum(case when eid = 2704 and is_delivery_available = False then event_count end) as total_users_off_delivery,
    sum(case when eid = 2704 and is_delivery_available = True then event_count end) as total_users_on_delivery,
    sum(case when eid = 3020 and search_correction_method = 'typo' then event_count end) as typo_disabled,
    sum(case when eid = 3019 and search_correction_method = 'typo' and search_correction_action = 'replace' then event_count end) as typo_replace,
    sum(case when eid = 3019 and search_correction_method = 'typo' and search_correction_action = 'suggest' then event_count end) as typo_suggest,
    sum(case when eid = 3020 and search_correction_method = 'typo_suggest' then event_count end) as typo_suggest_disabled,
    sum(case when eid = 3020 and search_correction_method = 'wordbreaker_digit' then event_count end) as wordbreaker_digit_disabled,
    sum(case when eid = 3019 and search_correction_method = 'wordbreaker_digit' and search_correction_action = 'replace' then event_count end) as wordbreaker_digit_replace,
    sum(case when eid = 3019 and search_correction_method = 'wordbreaker_digit' and search_correction_action = 'suggest' then event_count end) as wordbreaker_digit_suggest,
    sum(case when eid = 3020 and search_correction_method = 'wordbreaker_digit_suggest' then event_count end) as wordbreaker_digit_suggest_disabled,
    sum(case when eid = 3020 and search_correction_method = 'wordbreaker' then event_count end) as wordbreaker_disabled,
    sum(case when eid = 3019 and search_correction_method = 'wordbreaker' and search_correction_action = 'replace' then event_count end) as wordbreaker_replace,
    sum(case when eid = 3019 and search_correction_method = 'wordbreaker' and search_correction_action = 'suggest' then event_count end) as wordbreaker_suggest,
    sum(case when eid = 3020 and search_correction_method = 'wordbreaker_suggest' then event_count end) as wordbreaker_suggest_disabled
from clickstream_counters t
;

create metrics clickstream_counters_cookie as
select
    sum(case when ext_profile_off > 0 then 1 end) as ext_profile_off_uniq,
    sum(case when ext_profile_on > 0 then 1 end) as ext_profile_on_uniq,
    sum(case when profile_shop_views > 0 then 1 end) as profile_shop_viewers,
    sum(case when profile_views_any > 0 then 1 end) as profile_viewers_any,
    sum(case when profile_views_extended > 0 then 1 end) as profile_viewers_extended,
    sum(case when profile_views_public > 0 then 1 end) as profile_viewers_public,
    sum(case when shop_views > 0 then 1 end) as shop_viewers,
    sum(case when geo_redirect_replace > 0 then 1 end) as unq_geo_redirect_replace,
    sum(case when geo_redirect_suggest > 0 then 1 end) as unq_geo_redirect_suggest,
    sum(case when misspell_replace > 0 then 1 end) as unq_misspell_replace,
    sum(case when misspell_suggest > 0 then 1 end) as unq_misspell_suggest,
    sum(case when search_redirect_replace > 0 then 1 end) as unq_s_redirect_replace,
    sum(case when search_redirect_suggest > 0 then 1 end) as unq_s_redirect_suggest,
    sum(case when sqp_layout_replace > 0 then 1 end) as unq_sqp_layout_replace,
    sum(case when sqp_layout_suggest > 0 then 1 end) as unq_sqp_layout_suggest,
    sum(case when sqp_wordbreaker_digit_replace > 0 then 1 end) as unq_sqp_wordbreaker_digit_replace,
    sum(case when sqp_wordbreaker_digit_suggest > 0 then 1 end) as unq_sqp_wordbreaker_digit_suggest,
    sum(case when sqp_wordbreaker_replace > 0 then 1 end) as unq_sqp_wordbreaker_replace,
    sum(case when sqp_wordbreaker_suggest > 0 then 1 end) as unq_sqp_wordbreaker_suggest,
    sum(case when teleport_replace > 0 then 1 end) as unq_teleport_replace,
    sum(case when teleport_suggest > 0 then 1 end) as unq_teleport_suggest,
    sum(case when typo_replace > 0 then 1 end) as unq_typo_replace,
    sum(case when typo_suggest > 0 then 1 end) as unq_typo_suggest,
    sum(case when click_banner_download_app > 0 then 1 end) as user_click_banner_download_app,
    sum(case when click_banner_mygarage > 0 then 1 end) as user_click_banner_mygarage,
    sum(case when click_category_widget > 0 then 1 end) as user_click_category_widget,
    sum(case when click_featured_widget > 0 then 1 end) as user_click_featured_widget,
    sum(case when click_promo_widget > 0 then 1 end) as user_click_promo_widget,
    sum(case when click_recent_search_widget > 0 then 1 end) as user_click_recent_search_widget,
    sum(case when click_recommendations_widget > 0 then 1 end) as user_click_recommendations_widget,
    sum(case when click_search_widget > 0 then 1 end) as user_click_search_widget,
    sum(case when icebreakers_message_template_clicks > 0 then 1 end) as user_icebreakers_message_template_clicks,
    sum(case when icebreakers_message_template_clicks_msg > 0 then 1 end) as user_icebreakers_message_template_clicks_msg,
    sum(case when icebreakers_message_template_shows > 0 then 1 end) as user_icebreakers_message_template_shows,
    sum(case when icebreakers_message_template_shows_msg > 0 then 1 end) as user_icebreakers_message_template_shows_msg,
    sum(case when network_api_bad_request_error > 0 then 1 end) as user_network_api_bad_request_error,
    sum(case when network_api_error > 0 then 1 end) as user_network_api_error,
    sum(case when network_backend_error > 0 then 1 end) as user_network_backend_error,
    sum(case when network_client_error > 0 then 1 end) as user_network_client_error,
    sum(case when network_client_error2 > 0 then 1 end) as user_network_client_error2,
    sum(case when network_client_no_session_error > 0 then 1 end) as user_network_client_no_session_error,
    sum(case when network_client_parsing_error > 0 then 1 end) as user_network_client_parsing_error,
    sum(case when network_error > 0 then 1 end) as user_network_error,
    sum(case when network_forbidden_error > 0 then 1 end) as user_network_forbidden_error,
    sum(case when network_image_load_error > 0 then 1 end) as user_network_image_load_error,
    sum(case when network_network_error > 0 then 1 end) as user_network_network_error,
    sum(case when network_system_error > 0 then 1 end) as user_network_system_error,
    sum(case when network_unauthenticated_error > 0 then 1 end) as user_network_unauthenticated_error,
    sum(case when network_upload_error > 0 then 1 end) as user_network_upload_error,
    sum(case when notes_create > 0 then 1 end) as user_notes_create,
    sum(case when notes_delete > 0 then 1 end) as user_notes_delete,
    sum(case when notes_update > 0 then 1 end) as user_notes_update,
    sum(case when notifications_off_any > 0 then 1 end) as user_notifications_off_any,
    sum(case when notifications_off_profile > 0 then 1 end) as user_notifications_off_profile,
    sum(case when notifications_off_system > 0 then 1 end) as user_notifications_off_system,
    sum(case when notifications_on_any > 0 then 1 end) as user_notifications_on_any,
    sum(case when notifications_on_profile > 0 then 1 end) as user_notifications_on_profile,
    sum(case when notifications_on_system > 0 then 1 end) as user_notifications_on_system,
    sum(case when reject_banner_download_app > 0 then 1 end) as user_reject_banner_download_app,
    sum(case when show_banner_download_app > 0 then 1 end) as user_show_banner_download_app,
    sum(case when show_banner_mygarage > 0 then 1 end) as user_show_banner_mygarage,
    sum(case when show_category_widget > 0 then 1 end) as user_show_category_widget,
    sum(case when show_featured_widget > 0 then 1 end) as user_show_featured_widget,
    sum(case when show_promo_widget > 0 then 1 end) as user_show_promo_widget,
    sum(case when show_recent_search_widget > 0 then 1 end) as user_show_recent_search_widget,
    sum(case when show_recommendations_widget > 0 then 1 end) as user_show_recommendations_widget,
    sum(case when show_search_widget > 0 then 1 end) as user_show_search_widget,
    sum(case when favouriteseller_adds > 0 then 1 end) as users_favouriteseller_add,
    sum(case when favouriteseller_deletes > 0 then 1 end) as users_favouriteseller_delete,
    sum(case when fps_falls_below_10pct > 0 then 1 end) as users_fps_falls_below_10pct,
    sum(case when fps_falls_below_30pct > 0 then 1 end) as users_fps_falls_below_30pct,
    sum(case when fps_falls_below_50pct > 0 then 1 end) as users_fps_falls_below_50pct,
    sum(case when fps_falls_below_70pct > 0 then 1 end) as users_fps_falls_below_70pct,
    sum(case when fps_falls_below_85pct > 0 then 1 end) as users_fps_falls_below_85pct,
    sum(case when fps_falls_below_90pct > 0 then 1 end) as users_fps_falls_below_90pct,
    sum(case when fps_falls_below_95pct > 0 then 1 end) as users_fps_falls_below_95pct,
    sum(case when mic_access_denied > 0 then 1 end) as users_mic_access_denied,
    sum(case when mic_access_granted > 0 then 1 end) as users_mic_access_granted
from (
    select
        cookie_id, cookie,
        sum(case when eid = 3207 and placement = 'splash.banner' and page_type = 'main' and banner_id = 'child' and action_type = 'click-positive' then event_count end) as click_banner_download_app,
        sum(case when eid = 3207 and banner_id ilike '%mygarage%' then event_count end) as click_banner_mygarage,
        sum(case when eid = 4921 and from_page = 'vertical_category' then event_count end) as click_category_widget,
        sum(case when eid = 4921 and from_page = 'featured' then event_count end) as click_featured_widget,
        sum(case when eid = 4921 and from_page = 'vertical_promo' then event_count end) as click_promo_widget,
        sum(case when eid = 4921 and from_page = 'recentSearch' then event_count end) as click_recent_search_widget,
        sum(case when eid = 4921 and from_page = 'vertical_recommendations' then event_count end) as click_recommendations_widget,
        sum(case when eid = 4954 then event_count end) as click_search_widget,
        sum(case when eid = 5070 and ext_profile_is_using is null then event_count end) as ext_profile_off,
        sum(case when eid = 5070 and ext_profile_is_using = True then event_count end) as ext_profile_on,
        sum(case when eid = 2908 then event_count end) as favouriteseller_adds,
        sum(case when eid = 2909 then event_count end) as favouriteseller_deletes,
        sum(case when eid = 5243 and fps_threshold = 10 then event_count end) as fps_falls_below_10pct,
        sum(case when eid = 5243 and fps_threshold = 30 then event_count end) as fps_falls_below_30pct,
        sum(case when eid = 5243 and fps_threshold = 50 then event_count end) as fps_falls_below_50pct,
        sum(case when eid = 5243 and fps_threshold = 70 then event_count end) as fps_falls_below_70pct,
        sum(case when eid = 5243 and fps_threshold = 85 then event_count end) as fps_falls_below_85pct,
        sum(case when eid = 5243 and fps_threshold = 90 then event_count end) as fps_falls_below_90pct,
        sum(case when eid = 5243 and fps_threshold = 95 then event_count end) as fps_falls_below_95pct,
        sum(case when eid = 3019 and search_correction_method = 'geo_redirect' and search_correction_action = 'replace' then event_count end) as geo_redirect_replace,
        sum(case when eid = 3019 and search_correction_method = 'geo_redirect' and search_correction_action = 'suggest' then event_count end) as geo_redirect_suggest,
        sum(case when eid = 4210 and (source is null or source = 'item') then event_count end) as icebreakers_message_template_clicks,
        sum(case when eid = 4210 and (source in ('messenger', 'mini-messenger')) then event_count end) as icebreakers_message_template_clicks_msg,
        sum(case when eid = 4209 and (source is null or source = 'item') then event_count end) as icebreakers_message_template_shows,
        sum(case when eid = 4209 and (source in ('messenger', 'mini-messenger')) then event_count end) as icebreakers_message_template_shows_msg,
        sum(case when eid = 4100 and app_call_mic_access = False then event_count end) as mic_access_denied,
        sum(case when eid = 4100 and app_call_mic_access = True then event_count end) as mic_access_granted,
        sum(case when eid = 3019 and search_correction_method = 'misspell' and search_correction_action = 'replace' then event_count end) as misspell_replace,
        sum(case when eid = 3019 and search_correction_method = 'misspell' and search_correction_action = 'suggest' then event_count end) as misspell_suggest,
        sum(case when eid = 4599 and network_error_type = 'network system error' and network_error_sub_type = 'bad request' then event_count end) as network_api_bad_request_error,
        sum(case when eid = 4599 and network_error_type = 'api error' then event_count end) as network_api_error,
        sum(case when eid = 4599 and network_error_type = '2. backend error' then event_count end) as network_backend_error,
        sum(case when eid = 4599 and network_error_type = 'network client error' then event_count end) as network_client_error,
        sum(case when eid = 4599 and network_error_type = '2. client error' then event_count end) as network_client_error2,
        sum(case when eid = 4599 and network_error_type = 'network client error' and network_error_sub_type = 'attempt to send authorized request with no session' then event_count end) as network_client_no_session_error,
        sum(case when eid = 4599 and network_error_type = 'network client error' and network_error_sub_type = 'parsing failure' then event_count end) as network_client_parsing_error,
        sum(case when eid = 4599 then event_count end) as network_error,
        sum(case when eid = 4599 and network_error_type = 'forbidden' then event_count end) as network_forbidden_error,
        sum(case when eid = 4599 and network_error_type in ('2. image error', 'image load error') then event_count end) as network_image_load_error,
        sum(case when eid = 4599 and network_error_type = '2. network error' then event_count end) as network_network_error,
        sum(case when eid = 4599 and network_error_type = 'network system error' then event_count end) as network_system_error,
        sum(case when eid = 4599 and network_error_type = 'http unauthenticated' then event_count end) as network_unauthenticated_error,
        sum(case when eid = 4599 and network_error_type = '2. upload error' then event_count end) as network_upload_error,
        sum(case when eid = 2582 and action_type = 'create' then event_count end) as notes_create,
        sum(case when eid = 2582 and action_type = 'delete' then event_count end) as notes_delete,
        sum(case when eid = 2582 and action_type = 'update' then event_count end) as notes_update,
        sum(case when (eid = 2558 and is_notifications_on = False or eid = 2390 and notification_value = False) then event_count end) as notifications_off_any,
        sum(case when eid = 2390 and notification_value = False then event_count end) as notifications_off_profile,
        sum(case when eid = 2558 and is_notifications_on = False then event_count end) as notifications_off_system,
        sum(case when (eid = 2558 and is_notifications_on = True or eid = 2390 and notification_value = True) then event_count end) as notifications_on_any,
        sum(case when eid = 2390 and notification_value = True then event_count end) as notifications_on_profile,
        sum(case when eid = 2558 and is_notifications_on = True then event_count end) as notifications_on_system,
        sum(case when eid in (2016, 3060) then event_count end) as profile_shop_views,
        sum(case when eid = 2016 then event_count end) as profile_views_any,
        sum(case when eid = 2016 and profile_type = 'extended_profile' then event_count end) as profile_views_extended,
        sum(case when eid = 2016 and profile_type = 'public_profile' then event_count end) as profile_views_public,
        sum(case when eid = 3207 and placement = 'splash.banner' and page_type = 'main' and banner_id = 'child' and action_type = 'click-negative' then event_count end) as reject_banner_download_app,
        sum(case when eid = 3019 and search_correction_method = 'search_redirect' and search_correction_action = 'replace' then event_count end) as search_redirect_replace,
        sum(case when eid = 3019 and search_correction_method = 'search_redirect' and search_correction_action = 'suggest' then event_count end) as search_redirect_suggest,
        sum(case when eid = 3060 then event_count end) as shop_views,
        sum(case when eid = 3180 and placement = 'splash.banner' and page_type = 'main' and banner_id = 'child' then event_count end) as show_banner_download_app,
        sum(case when eid = 3180 and banner_id ilike '%mygarage%' then event_count end) as show_banner_mygarage,
        sum(case when eid = 4920 and from_page = 'vertical_category' then event_count end) as show_category_widget,
        sum(case when eid = 4920 and from_page = 'featured' then event_count end) as show_featured_widget,
        sum(case when eid = 4920 and from_page = 'vertical_promo' then event_count end) as show_promo_widget,
        sum(case when eid = 4920 and from_page = 'recentSearch' then event_count end) as show_recent_search_widget,
        sum(case when eid = 4920 and from_page = 'vertical_recommendations' then event_count end) as show_recommendations_widget,
        sum(case when eid = 4920 and from_page = 'vertical_filter' then event_count end) as show_search_widget,
        sum(case when eid = 3019 and search_correction_method = 'sqp_layout' and search_correction_action = 'replace' then event_count end) as sqp_layout_replace,
        sum(case when eid = 3019 and search_correction_method = 'sqp_layout' and search_correction_action = 'suggest' then event_count end) as sqp_layout_suggest,
        sum(case when eid = 3019 and search_correction_method = 'sqp_wordbreaker_digit' and search_correction_action = 'replace' then event_count end) as sqp_wordbreaker_digit_replace,
        sum(case when eid = 3019 and search_correction_method = 'sqp_wordbreaker_digit' and search_correction_action = 'suggest' then event_count end) as sqp_wordbreaker_digit_suggest,
        sum(case when eid = 3019 and search_correction_method = 'sqp_wordbreaker' and search_correction_action = 'replace' then event_count end) as sqp_wordbreaker_replace,
        sum(case when eid = 3019 and search_correction_method = 'sqp_wordbreaker' and search_correction_action = 'suggest' then event_count end) as sqp_wordbreaker_suggest,
        sum(case when eid = 3019 and search_correction_method = 'teleport' and search_correction_action = 'replace' then event_count end) as teleport_replace,
        sum(case when eid = 3019 and search_correction_method = 'teleport' and search_correction_action = 'suggest' then event_count end) as teleport_suggest,
        sum(case when eid = 3019 and search_correction_method = 'typo' and search_correction_action = 'replace' then event_count end) as typo_replace,
        sum(case when eid = 3019 and search_correction_method = 'typo' and search_correction_action = 'suggest' then event_count end) as typo_suggest
    from clickstream_counters t
    group by cookie_id, cookie
) _
;

create metrics clickstream_counters_item_id as
select
    sum(case when total_item_off_delivery > 0 then 1 end) as item_off_delivery,
    sum(case when total_item_on_delivery > 0 then 1 end) as item_on_delivery,
    sum(case when total_users_off_delivery > 0 then 1 end) as users_off_delivery,
    sum(case when total_users_on_delivery > 0 then 1 end) as users_on_delivery
from (
    select
        cookie_id, item_id,
        sum(case when eid = 2703 and is_delivery_available = False then event_count end) as total_item_off_delivery,
        sum(case when eid = 2703 and is_delivery_available = True then event_count end) as total_item_on_delivery,
        sum(case when eid = 2704 and is_delivery_available = False then event_count end) as total_users_off_delivery,
        sum(case when eid = 2704 and is_delivery_available = True then event_count end) as total_users_on_delivery
    from clickstream_counters t
    group by cookie_id, item_id
) _
;
