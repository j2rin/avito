create fact seller_item_active as
select
    t.event_date::date as __date__,
    t.user_id,
    t.item_id,
    t.platform_id,
    t.start_time,
    t.start_date,
    t.last_activation_time,
    t.last_activation_date,
    t.is_active,
    t.is_marketplace,
    t.is_message_forbidden,
    t.microcat_id,
    t.status_id,
    t.photo_count,
    t.description_word_count,
    t.contacts,
	t.contacts_msg,
	t.contacts_ph,
    t.favs_added,
    t.favs_removed,
    t.activations_count,
    t.activations_after_ttl_count,
    t.item_views,
    t.vas_mask,
    t.is_delivery_available,
	t.is_delivery_active,
	t.delivery_clicks,
	t.delivery_contacts,
    t.seller_rating,
    t.infmquery_id,
    t.location_id,
    t.user_id as user,
    t.item_id as item
from dma.seller_item_active_dimetra t
;

create metrics seller_item_active_item as
select
    sum(case when cnt_active_items > 0 then 1 end) as active_items,
    sum(case when cnt_active_items_0_photo > 0 then 1 end) as active_items_0_photo,
    sum(case when cnt_active_items_more_10_description_word > 0 then 1 end) as active_items_more_10_description_word,
    sum(case when cnt_active_items_more_10_photo > 0 then 1 end) as active_items_more_10_photo,
    sum(case when cnt_active_items_more_1_photo > 0 then 1 end) as active_items_more_1_photo,
    sum(case when cnt_active_items_more_3_photo > 0 then 1 end) as active_items_more_3_photo,
    sum(case when cnt_active_items_more_40_description_word > 0 then 1 end) as active_items_more_40_description_word,
    sum(case when cnt_active_items_more_5_description_word > 0 then 1 end) as active_items_more_5_description_word,
    sum(case when cnt_active_items_more_5_photo > 0 then 1 end) as active_items_more_5_photo,
    sum(case when cnt_new_items_0_photo > 0 then 1 end) as new_items_0_photo,
    sum(case when cnt_new_items_more_10_description_word > 0 then 1 end) as new_items_more_10_description_word,
    sum(case when cnt_new_items_more_10_photo > 0 then 1 end) as new_items_more_10_photo,
    sum(case when cnt_new_items_more_1_photo > 0 then 1 end) as new_items_more_1_photo,
    sum(case when cnt_new_items_more_3_photo > 0 then 1 end) as new_items_more_3_photo,
    sum(case when cnt_new_items_more_40_description_word > 0 then 1 end) as new_items_more_40_description_word,
    sum(case when cnt_new_items_more_5_description_word > 0 then 1 end) as new_items_more_5_description_word,
    sum(case when cnt_new_items_more_5_photo > 0 then 1 end) as new_items_more_5_photo,
    sum(case when seller_delivery_iv > 0 then 1 end) as seller_delivery_items_with_iv,
    sum(case when seller_favorites_added > 0 then 1 end) as seller_items_favorites_added,
    sum(case when seller_favorites_removed > 0 then 1 end) as seller_items_favorites_removed,
    sum(case when seller_btc > 0 then 1 end) as seller_items_with_btc,
    sum(case when seller_delivery_clicks > 0 then 1 end) as seller_items_with_delivery_clicks,
    sum(case when seller_delivery_contacts > 0 then 1 end) as seller_items_with_delivery_contacts,
    sum(case when seller_item_views > 0 then 1 end) as seller_items_with_item_views,
    sum(case when seller_contacts > 0 then 1 end) as sellers_items_with_contacts
from (
    select
        user_id, item,
        sum(case when is_active = True then 1 end) as cnt_active_items,
        sum(case when photo_count = 0 then 1 end) as cnt_active_items_0_photo,
        sum(case when description_word_count >= 10 then 1 end) as cnt_active_items_more_10_description_word,
        sum(case when photo_count >= 10 then 1 end) as cnt_active_items_more_10_photo,
        sum(case when photo_count >= 1 then 1 end) as cnt_active_items_more_1_photo,
        sum(case when photo_count >= 3 then 1 end) as cnt_active_items_more_3_photo,
        sum(case when description_word_count >= 40 then 1 end) as cnt_active_items_more_40_description_word,
        sum(case when description_word_count >= 5 then 1 end) as cnt_active_items_more_5_description_word,
        sum(case when photo_count >= 5 then 1 end) as cnt_active_items_more_5_photo,
        sum(case when start_date = event_date and photo_count = 0 then 1 end) as cnt_new_items_0_photo,
        sum(case when description_word_count >= 10 and start_date = event_date then 1 end) as cnt_new_items_more_10_description_word,
        sum(case when start_date = event_date and photo_count >= 10 then 1 end) as cnt_new_items_more_10_photo,
        sum(case when start_date = event_date and photo_count >= 1 then 1 end) as cnt_new_items_more_1_photo,
        sum(case when start_date = event_date and photo_count >= 3 then 1 end) as cnt_new_items_more_3_photo,
        sum(case when description_word_count >= 40 and start_date = event_date then 1 end) as cnt_new_items_more_40_description_word,
        sum(case when description_word_count >= 5 and start_date = event_date then 1 end) as cnt_new_items_more_5_description_word,
        sum(case when start_date = event_date and photo_count >= 5 then 1 end) as cnt_new_items_more_5_photo,
        sum(ifnull(favs_added, 0) + ifnull(contacts, 0)) as seller_btc,
        sum(contacts) as seller_contacts,
        sum(delivery_clicks) as seller_delivery_clicks,
        sum(delivery_contacts) as seller_delivery_contacts,
        sum(case when is_delivery_active = True then item_views end) as seller_delivery_iv,
        sum(favs_added) as seller_favorites_added,
        sum(favs_removed) as seller_favorites_removed,
        sum(item_views) as seller_item_views
    from seller_item_active t
    group by user_id, item
) _
;

create metrics seller_item_active as
select
    sum(case when is_active = True and is_marketplace = False then 1 end) as active_items_classified,
    sum(case when is_active = True and is_marketplace = True then 1 end) as active_items_marketplace,
    sum(case when is_active = True and is_message_forbidden = False then 1 end) as active_items_with_msg,
    sum(case when is_active = True and is_message_forbidden = False and contacts != 0 then 1 end) as active_items_with_msg_contacts,
    sum(case when is_active = True then 1 end) as cnt_active_items,
    sum(case when photo_count = 0 then 1 end) as cnt_active_items_0_photo,
    sum(case when description_word_count >= 10 then 1 end) as cnt_active_items_more_10_description_word,
    sum(case when photo_count >= 10 then 1 end) as cnt_active_items_more_10_photo,
    sum(case when photo_count >= 1 then 1 end) as cnt_active_items_more_1_photo,
    sum(case when photo_count >= 3 then 1 end) as cnt_active_items_more_3_photo,
    sum(case when description_word_count >= 40 then 1 end) as cnt_active_items_more_40_description_word,
    sum(case when description_word_count >= 5 then 1 end) as cnt_active_items_more_5_description_word,
    sum(case when photo_count >= 5 then 1 end) as cnt_active_items_more_5_photo,
    sum(case when is_active = True then address_length end) as cnt_item_address_length,
    sum(case when is_active = True and start_date = event_date then address_length end) as cnt_item_address_length_new,
    sum(case when activations_count > 1 and is_active = True and last_activation_date = event_date then address_length end) as cnt_item_address_length_reactivated,
    sum(case when start_date = event_date and photo_count = 0 then 1 end) as cnt_new_items_0_photo,
    sum(case when description_word_count >= 10 and start_date = event_date then 1 end) as cnt_new_items_more_10_description_word,
    sum(case when start_date = event_date and photo_count >= 10 then 1 end) as cnt_new_items_more_10_photo,
    sum(case when start_date = event_date and photo_count >= 1 then 1 end) as cnt_new_items_more_1_photo,
    sum(case when start_date = event_date and photo_count >= 3 then 1 end) as cnt_new_items_more_3_photo,
    sum(case when description_word_count >= 40 and start_date = event_date then 1 end) as cnt_new_items_more_40_description_word,
    sum(case when description_word_count >= 5 and start_date = event_date then 1 end) as cnt_new_items_more_5_description_word,
    sum(case when start_date = event_date and photo_count >= 5 then 1 end) as cnt_new_items_more_5_photo,
    sum(case when is_active = True and is_message_forbidden = False then item_views end) as item_views_with_msg,
    sum(case when is_active = True and location_distance <= 0.1 then 1 end) as items_100m_from_location,
    sum(case when is_active = True and location_distance <= 0.1 and start_date = event_date then 1 end) as items_100m_from_location_new,
    sum(case when activations_count > 1 and is_active = True and last_activation_date = event_date and location_distance <= 0.1 then 1 end) as items_100m_from_location_reactivated,
    sum(case when is_active = True and location_distance > 200 then 1 end) as items_200_plus_km_from_location,
    sum(case when is_active = True and location_distance > 200 and start_date = event_date then 1 end) as items_200_plus_km_from_location_new,
    sum(case when activations_count > 1 and is_active = True and last_activation_date = event_date and location_distance > 200 then 1 end) as items_200_plus_km_from_location_reactivated,
    sum(case when is_active = True and location_distance <= 0.02 then 1 end) as items_20m_from_location,
    sum(case when is_active = True and location_distance <= 0.02 and start_date = event_date then 1 end) as items_20m_from_location_new,
    sum(case when activations_count > 1 and is_active = True and last_activation_date = event_date and location_distance <= 0.02 then 1 end) as items_20m_from_location_reactivated,
    sum(case when is_active = True and location_distance <= 0.5 then 1 end) as items_500m_from_location,
    sum(case when is_active = True and location_distance <= 0.5 and start_date = event_date then 1 end) as items_500m_from_location_new,
    sum(case when activations_count > 1 and is_active = True and last_activation_date = event_date and location_distance <= 0.5 then 1 end) as items_500m_from_location_reactivated,
    sum(case when is_active = True and is_delivery_available = True then 1 end) as items_delivery_available,
    sum(case when has_address_id = False and is_active = True then 1 end) as items_no_address_id,
    sum(case when has_address_id = False and is_active = True and start_date = event_date then 1 end) as items_no_address_id_new,
    sum(case when activations_count > 1 and has_address_id = False and is_active = True and last_activation_date = event_date then 1 end) as items_no_address_id_reactivated,
    sum(case when has_address = False and is_active = True then 1 end) as items_no_address_string,
    sum(case when has_address = False and is_active = True and start_date = event_date then 1 end) as items_no_address_string_new,
    sum(case when activations_count > 1 and has_address = False and is_active = True and last_activation_date = event_date then 1 end) as items_no_address_string_reactivated,
    sum(case when is_active = True and min_kind_level in (120, 130, 140) then 1 end) as items_no_city,
    sum(case when is_active = True and min_kind_level in (120, 130, 140) and start_date = event_date then 1 end) as items_no_city_new,
    sum(case when activations_count > 1 and is_active = True and last_activation_date = event_date and min_kind_level in (120, 130, 140) then 1 end) as items_no_city_reactivated,
    sum(case when is_active = True and (location_distance is null or location_distance = -1) then 1 end) as items_no_coordinates,
    sum(case when is_active = True and start_date = event_date and (location_distance is null or location_distance = -1) then 1 end) as items_no_coordinates_new,
    sum(case when activations_count > 1 and is_active = True and last_activation_date = event_date and (location_distance is null or location_distance = -1) then 1 end) as items_no_coordinates_reactivated,
    sum(case when has_address_id = True and is_active = True then 1 end) as items_with_address_id,
    sum(case when has_address_id = True and is_active = True and start_date = event_date then 1 end) as items_with_address_id_new,
    sum(case when activations_count > 1 and has_address_id = True and is_active = True and last_activation_date = event_date then 1 end) as items_with_address_id_reactivated,
    sum(case when has_address = True and is_active = True then 1 end) as items_with_address_string,
    sum(case when has_address = True and is_active = True and start_date = event_date then 1 end) as items_with_address_string_new,
    sum(case when activations_count > 1 and has_address = True and is_active = True and last_activation_date = event_date then 1 end) as items_with_address_string_reactivated,
    sum(case when is_active = True and (has_address_id = False or location_distance is null or location_distance <= 0.1 or location_distance = -1 or min_kind_level not in (40, 50, 55, 60, 70)) then 1 end) as items_with_bad_address,
    sum(case when is_active = True and start_date = event_date and (has_address_id = False or location_distance is null or location_distance <= 0.1 or location_distance = -1 or min_kind_level not in (40, 50, 55, 60, 70)) then 1 end) as items_with_bad_address_new,
    sum(case when is_active = True and last_activation_date = event_date and activations_count > 1 and (has_address_id = False or location_distance is null or location_distance <= 0.1 or location_distance = -1 or min_kind_level not in (40, 50, 55, 60, 70)) then 1 end) as items_with_bad_address_reactivated,
    sum(case when is_active = True and min_kind_level = 40 then 1 end) as items_with_building,
    sum(case when is_active = True and min_kind_level = 40 and start_date = event_date then 1 end) as items_with_building_new,
    sum(case when activations_count > 1 and is_active = True and last_activation_date = event_date and min_kind_level = 40 then 1 end) as items_with_building_reactivated,
    sum(case when is_active = True and min_kind_level in (100, 110) then 1 end) as items_with_city,
    sum(case when is_active = True and min_kind_level in (100, 110) and start_date = event_date then 1 end) as items_with_city_new,
    sum(case when activations_count > 1 and is_active = True and last_activation_date = event_date and min_kind_level in (100, 110) then 1 end) as items_with_city_reactivated,
    sum(case when is_active = True and location_distance >= -1 then 1 end) as items_with_coordinates,
    sum(case when is_active = True and location_distance >= -1 and start_date = event_date then 1 end) as items_with_coordinates_new,
    sum(case when activations_count > 1 and is_active = True and last_activation_date = event_date and location_distance >= -1 then 1 end) as items_with_coordinates_reactivated,
    sum(case when is_active = True and is_delivery_active = True then 1 end) as items_with_delivery,
    sum(case when is_active = True and min_kind_level in (60, 70) then 1 end) as items_with_district,
    sum(case when is_active = True and location_distance <= 0.1 and min_kind_level in (60, 70) then 1 end) as items_with_district_100m_from_location,
    sum(case when is_active = True and location_distance <= 0.1 and min_kind_level in (60, 70) and start_date = event_date then 1 end) as items_with_district_100m_from_location_new,
    sum(case when activations_count > 1 and is_active = True and last_activation_date = event_date and location_distance <= 0.1 and min_kind_level in (60, 70) then 1 end) as items_with_district_100m_from_location_reactivated,
    sum(case when is_active = True and location_distance <= 0.5 and min_kind_level in (60, 70) then 1 end) as items_with_district_500m_from_location,
    sum(case when is_active = True and location_distance <= 0.5 and min_kind_level in (60, 70) and start_date = event_date then 1 end) as items_with_district_500m_from_location_new,
    sum(case when activations_count > 1 and is_active = True and last_activation_date = event_date and location_distance <= 0.5 and min_kind_level in (60, 70) then 1 end) as items_with_district_500m_from_location_reactivated,
    sum(case when is_active = True and min_kind_level in (60, 70) and start_date = event_date then 1 end) as items_with_district_new,
    sum(case when activations_count > 1 and is_active = True and last_activation_date = event_date and min_kind_level in (60, 70) then 1 end) as items_with_district_reactivated,
    sum(case when is_active = True and min_kind_level in (10, 20, 30, 80, 90) then 1 end) as items_with_marginal_address,
    sum(case when is_active = True and min_kind_level in (10, 20, 30, 80, 90) and start_date = event_date then 1 end) as items_with_marginal_address_new,
    sum(case when activations_count > 1 and is_active = True and last_activation_date = event_date and min_kind_level in (10, 20, 30, 80, 90) then 1 end) as items_with_marginal_address_reactivated,
    sum(case when is_active = True and min_kind_level = 55 then 1 end) as items_with_metro,
    sum(case when is_active = True and location_distance <= 0.1 and min_kind_level = 55 then 1 end) as items_with_metro_100m_from_location,
    sum(case when is_active = True and location_distance <= 0.1 and min_kind_level = 55 and start_date = event_date then 1 end) as items_with_metro_100m_from_location_new,
    sum(case when activations_count > 1 and is_active = True and last_activation_date = event_date and location_distance <= 0.1 and min_kind_level = 55 then 1 end) as items_with_metro_100m_from_location_reactivated,
    sum(case when is_active = True and location_distance <= 0.5 and min_kind_level = 55 then 1 end) as items_with_metro_500m_from_location,
    sum(case when is_active = True and location_distance <= 0.5 and min_kind_level = 55 and start_date = event_date then 1 end) as items_with_metro_500m_from_location_new,
    sum(case when activations_count > 1 and is_active = True and last_activation_date = event_date and location_distance <= 0.5 and min_kind_level = 55 then 1 end) as items_with_metro_500m_from_location_reactivated,
    sum(case when is_active = True and min_kind_level = 55 and start_date = event_date then 1 end) as items_with_metro_new,
    sum(case when activations_count > 1 and is_active = True and last_activation_date = event_date and min_kind_level = 55 then 1 end) as items_with_metro_reactivated,
    sum(case when is_active = True and seller_rating = 1 then 1 end) as items_with_rating_1,
    sum(case when is_active = True and seller_rating = 2 then 1 end) as items_with_rating_2,
    sum(case when is_active = True and seller_rating = 3 then 1 end) as items_with_rating_3,
    sum(case when is_active = True and seller_rating = 4 then 1 end) as items_with_rating_4,
    sum(case when is_active = True and seller_rating = 5 then 1 end) as items_with_rating_5,
    sum(case when is_active = True and seller_rating in (1, 2, 3, 4, 5) then 1 end) as items_with_rating_new,
    sum(case when is_active = True and min_kind_level = 50 then 1 end) as items_with_street,
    sum(case when is_active = True and location_distance <= 0.1 and min_kind_level = 50 then 1 end) as items_with_street_100m_from_location,
    sum(case when is_active = True and location_distance <= 0.1 and min_kind_level = 50 and start_date = event_date then 1 end) as items_with_street_100m_from_location_new,
    sum(case when activations_count > 1 and is_active = True and last_activation_date = event_date and location_distance <= 0.1 and min_kind_level = 50 then 1 end) as items_with_street_100m_from_location_reactivated,
    sum(case when is_active = True and location_distance <= 0.5 and min_kind_level = 50 then 1 end) as items_with_street_500m_from_location,
    sum(case when is_active = True and location_distance <= 0.5 and min_kind_level = 50 and start_date = event_date then 1 end) as items_with_street_500m_from_location_new,
    sum(case when activations_count > 1 and is_active = True and last_activation_date = event_date and location_distance <= 0.5 and min_kind_level = 50 then 1 end) as items_with_street_500m_from_location_reactivated,
    sum(case when is_active = True and min_kind_level = 50 and start_date = event_date then 1 end) as items_with_street_new,
    sum(case when activations_count > 1 and is_active = True and last_activation_date = event_date and min_kind_level = 50 then 1 end) as items_with_street_reactivated,
    sum(ifnull(favs_added, 0) + ifnull(contacts, 0)) as seller_btc,
    sum(case when vas_mask > 0 then ifnull(favs_added, 0) + ifnull(contacts, 0) end) as seller_btc_vas,
    sum(contacts) as seller_contacts,
    sum(contacts_msg) as seller_contacts_messenger,
    sum(case when is_delivery_available = True then contacts end) as seller_contacts_on_deliverable_items,
    sum(case when is_delivery_active = True then contacts end) as seller_contacts_on_delivery_items,
    sum(contacts_ph) as seller_contacts_phone_views,
    sum(case when vas_mask > 0 then contacts end) as seller_contacts_vas,
    sum(case when is_delivery_available = True then item_views end) as seller_deliverable_iv,
    sum(case when is_delivery_available = True then item_views end) as seller_delivery_available_iv,
    sum(delivery_clicks) as seller_delivery_clicks,
    sum(delivery_contacts) as seller_delivery_contacts,
    sum(case when is_delivery_active = True then item_views end) as seller_delivery_iv,
    sum(favs_added) as seller_favorites_added,
    sum(favs_removed) as seller_favorites_removed,
    sum(item_views) as seller_item_views,
    sum(case when vas_mask > 0 then item_views end) as seller_item_views_vas
from seller_item_active t
;

create metrics seller_item_active_user_logcat as
select
    sum(case when cnt_active_items > 0 then 1 end) as active_listers,
    sum(case when items_with_rating_new > 0 then 1 end) as listers_with_rating,
    sum(case when items_with_rating_1 > 0 then 1 end) as listers_with_rating_1,
    sum(case when items_with_rating_2 > 0 then 1 end) as listers_with_rating_2,
    sum(case when items_with_rating_3 > 0 then 1 end) as listers_with_rating_3,
    sum(case when items_with_rating_4 > 0 then 1 end) as listers_with_rating_4,
    sum(case when items_with_rating_5 > 0 then 1 end) as listers_with_rating_5
from (
    select
        user_id, hash(t.user_id, t.logical_category_id) as user_logcat,
        sum(case when is_active = True then 1 end) as cnt_active_items,
        sum(case when is_active = True and seller_rating = 1 then 1 end) as items_with_rating_1,
        sum(case when is_active = True and seller_rating = 2 then 1 end) as items_with_rating_2,
        sum(case when is_active = True and seller_rating = 3 then 1 end) as items_with_rating_3,
        sum(case when is_active = True and seller_rating = 4 then 1 end) as items_with_rating_4,
        sum(case when is_active = True and seller_rating = 5 then 1 end) as items_with_rating_5,
        sum(case when is_active = True and seller_rating in (1, 2, 3, 4, 5) then 1 end) as items_with_rating_new
    from seller_item_active t
    group by user_id, hash(t.user_id, t.logical_category_id)
) _
;

create metrics seller_item_active_user as
select
    sum(case when seller_contacts_on_deliverable_items > 0 then 1 end) as delivery_available_sellers_with_contact,
    sum(case when seller_contacts_on_delivery_items > 0 then 1 end) as delivery_sellers_with_contact,
    sum(case when seller_favorites_added > 0 then 1 end) as sellers_favorite_added,
    sum(case when seller_favorites_removed > 0 then 1 end) as sellers_favorite_removed,
    sum(case when seller_btc > 0 then 1 end) as sellers_with_btc,
    sum(case when seller_btc_vas > 0 then 1 end) as sellers_with_btc_vas,
    sum(case when seller_contacts > 0 then 1 end) as sellers_with_contacts,
    sum(case when seller_contacts_vas > 0 then 1 end) as sellers_with_contacts_vas,
    sum(case when items_delivery_available > 0 then 1 end) as sellers_with_delivery_available_item,
    sum(case when seller_delivery_clicks > 0 then 1 end) as sellers_with_delivery_click,
    sum(case when seller_delivery_contacts > 0 then 1 end) as sellers_with_delivery_contact,
    sum(case when items_with_delivery > 0 then 1 end) as sellers_with_delivery_item,
    sum(case when seller_item_views > 0 then 1 end) as sellers_with_item_views,
    sum(case when seller_item_views_vas > 0 then 1 end) as sellers_with_item_views_vas,
    sum(case when seller_contacts_messenger > 0 then 1 end) as sellers_with_messages,
    sum(case when seller_contacts_phone_views > 0 then 1 end) as sellers_with_phone_views,
    sum(case when items_with_rating_1 > 0 then 1 end) as sellers_with_rating_1_new,
    sum(case when items_with_rating_2 > 0 then 1 end) as sellers_with_rating_2_new,
    sum(case when items_with_rating_3 > 0 then 1 end) as sellers_with_rating_3_new,
    sum(case when items_with_rating_4 > 0 then 1 end) as sellers_with_rating_4_new,
    sum(case when items_with_rating_5 > 0 then 1 end) as sellers_with_rating_5_new,
    sum(case when items_with_rating_new > 0 then 1 end) as sellers_with_rating_new,
    sum(case when cnt_active_items_0_photo > 0 then 1 end) as users_active_item_0_photo,
    sum(case when cnt_active_items_more_10_description_word > 0 then 1 end) as users_active_item_more_10_description_word,
    sum(case when cnt_active_items_more_10_photo > 0 then 1 end) as users_active_item_more_10_photo,
    sum(case when cnt_active_items_more_1_photo > 0 then 1 end) as users_active_item_more_1_photo,
    sum(case when cnt_active_items_more_3_photo > 0 then 1 end) as users_active_item_more_3_photo,
    sum(case when cnt_active_items_more_40_description_word > 0 then 1 end) as users_active_item_more_40_description_word,
    sum(case when cnt_active_items_more_5_description_word > 0 then 1 end) as users_active_item_more_5_description_word,
    sum(case when cnt_active_items_more_5_photo > 0 then 1 end) as users_active_item_more_5_photo,
    sum(case when cnt_active_items > 0 then 1 end) as users_active_items,
    sum(case when cnt_new_items_0_photo > 0 then 1 end) as users_new_item_0_photo,
    sum(case when cnt_new_items_more_10_description_word > 0 then 1 end) as users_new_item_more_10_description_word,
    sum(case when cnt_new_items_more_10_photo > 0 then 1 end) as users_new_item_more_10_photo,
    sum(case when cnt_new_items_more_1_photo > 0 then 1 end) as users_new_item_more_1_photo,
    sum(case when cnt_new_items_more_3_photo > 0 then 1 end) as users_new_item_more_3_photo,
    sum(case when cnt_new_items_more_40_description_word > 0 then 1 end) as users_new_item_more_40_description_word,
    sum(case when cnt_new_items_more_5_description_word > 0 then 1 end) as users_new_item_more_5_description_word,
    sum(case when cnt_new_items_more_5_photo > 0 then 1 end) as users_new_item_more_5_photo
from (
    select
        user_id, user,
        sum(case when is_active = True then 1 end) as cnt_active_items,
        sum(case when photo_count = 0 then 1 end) as cnt_active_items_0_photo,
        sum(case when description_word_count >= 10 then 1 end) as cnt_active_items_more_10_description_word,
        sum(case when photo_count >= 10 then 1 end) as cnt_active_items_more_10_photo,
        sum(case when photo_count >= 1 then 1 end) as cnt_active_items_more_1_photo,
        sum(case when photo_count >= 3 then 1 end) as cnt_active_items_more_3_photo,
        sum(case when description_word_count >= 40 then 1 end) as cnt_active_items_more_40_description_word,
        sum(case when description_word_count >= 5 then 1 end) as cnt_active_items_more_5_description_word,
        sum(case when photo_count >= 5 then 1 end) as cnt_active_items_more_5_photo,
        sum(case when start_date = event_date and photo_count = 0 then 1 end) as cnt_new_items_0_photo,
        sum(case when description_word_count >= 10 and start_date = event_date then 1 end) as cnt_new_items_more_10_description_word,
        sum(case when start_date = event_date and photo_count >= 10 then 1 end) as cnt_new_items_more_10_photo,
        sum(case when start_date = event_date and photo_count >= 1 then 1 end) as cnt_new_items_more_1_photo,
        sum(case when start_date = event_date and photo_count >= 3 then 1 end) as cnt_new_items_more_3_photo,
        sum(case when description_word_count >= 40 and start_date = event_date then 1 end) as cnt_new_items_more_40_description_word,
        sum(case when description_word_count >= 5 and start_date = event_date then 1 end) as cnt_new_items_more_5_description_word,
        sum(case when start_date = event_date and photo_count >= 5 then 1 end) as cnt_new_items_more_5_photo,
        sum(case when is_active = True and is_delivery_available = True then 1 end) as items_delivery_available,
        sum(case when is_active = True and is_delivery_active = True then 1 end) as items_with_delivery,
        sum(case when is_active = True and seller_rating = 1 then 1 end) as items_with_rating_1,
        sum(case when is_active = True and seller_rating = 2 then 1 end) as items_with_rating_2,
        sum(case when is_active = True and seller_rating = 3 then 1 end) as items_with_rating_3,
        sum(case when is_active = True and seller_rating = 4 then 1 end) as items_with_rating_4,
        sum(case when is_active = True and seller_rating = 5 then 1 end) as items_with_rating_5,
        sum(case when is_active = True and seller_rating in (1, 2, 3, 4, 5) then 1 end) as items_with_rating_new,
        sum(ifnull(favs_added, 0) + ifnull(contacts, 0)) as seller_btc,
        sum(case when vas_mask > 0 then ifnull(favs_added, 0) + ifnull(contacts, 0) end) as seller_btc_vas,
        sum(contacts) as seller_contacts,
        sum(contacts_msg) as seller_contacts_messenger,
        sum(case when is_delivery_available = True then contacts end) as seller_contacts_on_deliverable_items,
        sum(case when is_delivery_active = True then contacts end) as seller_contacts_on_delivery_items,
        sum(contacts_ph) as seller_contacts_phone_views,
        sum(case when vas_mask > 0 then contacts end) as seller_contacts_vas,
        sum(delivery_clicks) as seller_delivery_clicks,
        sum(delivery_contacts) as seller_delivery_contacts,
        sum(favs_added) as seller_favorites_added,
        sum(favs_removed) as seller_favorites_removed,
        sum(item_views) as seller_item_views,
        sum(case when vas_mask > 0 then item_views end) as seller_item_views_vas
    from seller_item_active t
    group by user_id, user
) _
;

create metrics seller_item_active_user_city_id as
select
    sum(case when cnt_active_items > 10 then 1 end) as user_active_items_10plus_locations,
    sum(case when cnt_active_items > 1 then 1 end) as user_active_items_1plus_locations,
    sum(case when cnt_active_items > 2 then 1 end) as user_active_items_2plus_locations,
    sum(case when cnt_active_items > 5 then 1 end) as user_active_items_5plus_locations
from (
    select
        user_id, user,
        sum(case when cnt_active_items > 0 then 1 end) as cnt_active_items
    from (
        select
            user_id, user, city_id,
            sum(case when is_active = True then 1 end) as cnt_active_items
        from seller_item_active t
        group by user_id, user, city_id
    ) _
    group by user_id, user
) _
;

create metrics seller_item_active_user_microcat_id_location_id as
select
    sum(case when cnt_active_items > 0 then 1 end) as user_active_items_10plus_locations_microcat,
    sum(case when cnt_active_items > 0 then 1 end) as user_active_items_1plus_locations_microcat,
    sum(case when cnt_active_items > 0 then 1 end) as user_active_items_2plus_locations_microcat,
    sum(case when cnt_active_items > 0 then 1 end) as user_active_items_5plus_locations_microcat
from (
    select
        user_id, user,
        sum(case when cnt_active_items > 10 then 1 end) as cnt_active_items
    from (
        select
            user_id, user, microcat_id,
            sum(case when cnt_active_items > 0 then 1 end) as cnt_active_items
        from (
            select
                user_id, user, microcat_id, location_id,
                sum(case when is_active = True then 1 end) as cnt_active_items
            from seller_item_active t
            group by user_id, user, microcat_id, location_id
        ) _
        group by user_id, user, microcat_id
    ) _
    group by user_id, user
) _
;

create metrics seller_item_active_location_id as
select
    sum(case when cnt_active_items > 0 then 1 end) as user_active_items_locations
from (
    select
        user_id, location_id,
        sum(case when is_active = True then 1 end) as cnt_active_items
    from seller_item_active t
    group by user_id, location_id
) _
;
