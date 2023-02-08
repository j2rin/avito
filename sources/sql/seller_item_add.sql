with item_add_chain_metrics as (select
      eventchain_id,
      cookie_id,
      user_id,
      multiple_sessions_event,
      was_logged_in_at_start,
      had_registration,
      had_login,
      chain_start_time,
      chain_finish_time,
      chain_item_create_time,
      chain_item_confirm_time,
      chain_user_reg_time,
      chain_phone_check_time,
      chain_auth_start_time,
      chain_wizard_click_time,
      chain_wizard_last_click_time,
      chain_title_add_time,
      chain_description_add_time,
      chain_image_add_time,
      chain_image_add_count,
      chain_image_delete_time,
      chain_image_delete_count,
      chain_image_reorder_time,
      chain_image_change_time,
      chain_cv_image_upload_start_time,
      chain_cv_user_suggest_view_time,
      chain_cv_response_time,
      chain_cv_suggest_title,
      cv_suggested_microcats,
      chain_contacts_screen_open_time,
      chain_address_location_autosuggest_time,
      chain_address_type_in_time,
      chain_address_suggest_click_time,
      chain_map_move_time,
      item_id,
      item_add_form_ErrorCode,
      UserAgent_id,
      location_id,
      VasPackage,
      ListingFeeStatus,
      ItemOriginal_id,
      Item_Add_ErrorText,
      Rules,
      SocialNetwork_id,
      t.microcat_id,
      item_seq_number,
      chain_geo_error_time,
      description_suggest_tags_count,
      chain_first_item_add_close_time,
      chain_last_item_add_close_time,
      chain_first_form_input_time,
      chain_last_form_input_time,
      chain_last_FormInputFieldName,
      chain_last_FormInputFieldValue,
      chain_price_add_time,
      chain_lf_show_time,
      proactive_rules_text,
      chain_final_page_time,
      chain_draft_dialog_open_time,
      chain_draft_continue_time,
      chain_auto_sts_recognition_server_time,
      chain_auto_sts_recognition_shown_time,
      chain_first_item_add_event_time,
      t.launch_id,
      ClientSideAppVersion,
      chain_cv_suggest_use_category,
      chain_cv_suggest_use_title,
      chain_cv_suggest_model_version,
      title_suggested_microcats,
      chain_title_microcategory_suggest_time,
      chain_title_for_category_suggest,
      chain_select_category_manual_time,
      chain_select_category_suggest_time,
      chain_title_suggest_click_count,
      chain_title_suggest_show_count,
      number_suggest_selected_microcat,
      cross_platform_item_add,
      chain_last_screen_open_time,
      chain_last_screen_open_name,
      chain_item_create_time::date as item_create_date,
      chain_start_time::date as event_date,
      chain_start_time::date as item_add_start_date,
      business_platform as platform_id,
      datediff('second', chain_start_time, chain_item_create_time) as duration_sec,
      1 as observation_value,
      nvl(lc.vertical_id, cm.vertical_id)                       as vertical_id,
      nvl(lc.logical_category_id, cm.logical_category_id)       as logical_category_id
from dma.item_add_chain_metrics t
left join infomodel.current_infmquery_category ic on ic.infmquery_id = t.infmquery_id
left join dma.current_logical_categories lc on lc.logcat_id = ic.logcat_id
left join DMA.current_microcategories cm on cm.microcat_id = t.microcat_id
where user_id is not null)
select 
      eventchain_id,
      cookie_id,
      t.user_id,
      multiple_sessions_event,
      was_logged_in_at_start,
      had_registration,
      had_login,
      chain_start_time,
      chain_finish_time,
      chain_item_create_time,
      chain_item_confirm_time,
      chain_user_reg_time,
      chain_phone_check_time,
      chain_auth_start_time,
      chain_wizard_click_time,
      chain_wizard_last_click_time,
      chain_title_add_time,
      chain_description_add_time,
      chain_image_add_time,
      chain_image_add_count,
      chain_image_delete_time,
      chain_image_delete_count,
      chain_image_reorder_time,
      chain_image_change_time,
      chain_cv_image_upload_start_time,
      chain_cv_user_suggest_view_time,
      chain_cv_response_time,
      chain_cv_suggest_title,
      cv_suggested_microcats,
      chain_contacts_screen_open_time,
      chain_address_location_autosuggest_time,
      chain_address_type_in_time,
      chain_address_suggest_click_time,
      chain_map_move_time,
      item_id,
      item_add_form_ErrorCode,
      UserAgent_id,
      location_id,
      VasPackage,
      ListingFeeStatus,
      ItemOriginal_id,
      Item_Add_ErrorText,
      Rules,
      SocialNetwork_id,
      microcat_id,
      item_seq_number,
      chain_geo_error_time,
      description_suggest_tags_count,
      chain_first_item_add_close_time,
      chain_last_item_add_close_time,
      chain_first_form_input_time,
      chain_last_form_input_time,
      chain_last_FormInputFieldName,
      chain_last_FormInputFieldValue,
      chain_price_add_time,
      chain_lf_show_time,
      proactive_rules_text,
      chain_final_page_time,
      chain_draft_dialog_open_time,
      chain_draft_continue_time,
      chain_auto_sts_recognition_server_time,
      chain_auto_sts_recognition_shown_time,
      chain_first_item_add_event_time,
      t.launch_id,
      ClientSideAppVersion,
      chain_cv_suggest_use_category,
      chain_cv_suggest_use_title,
      chain_cv_suggest_model_version,
      title_suggested_microcats,
      chain_title_microcategory_suggest_time,
      chain_title_for_category_suggest,
      chain_select_category_manual_time,
      chain_select_category_suggest_time,
      chain_title_suggest_click_count,
      chain_title_suggest_show_count,
      number_suggest_selected_microcat,
      cross_platform_item_add,
      chain_last_screen_open_time,
      chain_last_screen_open_name,
      item_create_date,
      event_date,
      item_add_start_date,
      platform_id,
      duration_sec,
      observation_value,
      vertical_id,
      t.logical_category_id,
      nvl(usm.user_segment, ls.segment) as user_segment_market
from item_add_chain_metrics t
left join /*+jtype(h),distrib(l,b)*/ dict.segmentation_ranks ls on ls.logical_category_id = t.logical_category_id and ls.is_default
left join /*+distrib(l,a)*/ dma.user_segment_market usm on t.user_id = usm.user_id and t.logical_category_id = usm.logical_category_id
                                                                and t.event_date interpolate previous value usm.converting_date


