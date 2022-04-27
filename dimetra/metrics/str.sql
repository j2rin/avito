create fact str as
select
    t.cookie_id,
    t.event_date,
    t.observation_name,
    t.observation_value
from dma.vo_str t
;

create metrics str as
select
    sum(case when observation_name = 'buyer_str_booking_cost' then observation_value end) as buyer_str_booking_cost,
    sum(case when observation_name = 'buyer_str_bookings' then observation_value end) as buyer_str_bookings,
    sum(case when observation_name = 'buyer_str_bookings_canceled' then observation_value end) as buyer_str_bookings_canceled,
    sum(case when observation_name = 'buyer_str_bookings_comfirmed' then observation_value end) as buyer_str_bookings_comfirmed,
    sum(case when observation_name = 'buyer_str_bookings_expired' then observation_value end) as buyer_str_bookings_expired,
    sum(case when observation_name = 'buyer_str_bookings_paid' then observation_value end) as buyer_str_bookings_paid,
    sum(case when observation_name = 'buyer_str_bookings_voided' then observation_value end) as buyer_str_bookings_voided,
    sum(case when observation_name = 'buyer_str_deals' then observation_value end) as buyer_str_deals,
    sum(case when observation_name = 'buyer_str_paid' then observation_value end) as buyer_str_paid,
    sum(case when observation_name = 'buyer_str_ts_booking_cost' then observation_value end) as buyer_str_ts_booking_cost,
    sum(case when observation_name = 'buyer_str_ts_bookings' then observation_value end) as buyer_str_ts_bookings,
    sum(case when observation_name = 'buyer_str_ts_bookings_canceled' then observation_value end) as buyer_str_ts_bookings_canceled,
    sum(case when observation_name = 'buyer_str_ts_bookings_comfirmed' then observation_value end) as buyer_str_ts_bookings_comfirmed,
    sum(case when observation_name = 'buyer_str_ts_bookings_expired' then observation_value end) as buyer_str_ts_bookings_expired,
    sum(case when observation_name = 'buyer_str_ts_bookings_paid' then observation_value end) as buyer_str_ts_bookings_paid,
    sum(case when observation_name = 'buyer_str_ts_bookings_voided' then observation_value end) as buyer_str_ts_bookings_voided,
    sum(case when observation_name = 'buyer_str_ts_deals' then observation_value end) as buyer_str_ts_deals,
    sum(case when observation_name = 'buyer_str_ts_paid' then observation_value end) as buyer_str_ts_paid,
    sum(case when observation_name = 'items_with_str_soa' then observation_value end) as cnt_items_with_str_soa,
    sum(case when observation_name = 'helpdesk_str_tickets' then observation_value end) as helpdesk_str_tickets,
    sum(case when observation_name = 'item_off_str' then observation_value end) as item_off_str,
    sum(case when observation_name = 'items_with_str' then observation_value end) as items_with_str,
    sum(case when observation_name = 'seller_str_bookings' then observation_value end) as seller_str_bookings,
    sum(case when observation_name = 'seller_str_bookings_canceled' then observation_value end) as seller_str_bookings_canceled,
    sum(case when observation_name = 'seller_str_bookings_comfirmed' then observation_value end) as seller_str_bookings_comfirmed,
    sum(case when observation_name = 'seller_str_bookings_expired' then observation_value end) as seller_str_bookings_expired,
    sum(case when observation_name = 'seller_str_bookings_paid' then observation_value end) as seller_str_bookings_paid,
    sum(case when observation_name = 'seller_str_deals' then observation_value end) as seller_str_deals,
    sum(case when observation_name = 'seller_payout_amount' then observation_value end) as seller_str_payout_amount,
    sum(case when observation_name = 'seller_payout_fee' then observation_value end) as seller_str_payout_fee,
    sum(case when observation_name = 'str_click' then observation_value end) as str_click,
    sum(case when observation_name = 'str_contact' then observation_value end) as str_contact,
    sum(case when observation_name = 'item_view' then observation_value end) as str_item_view,
    sum(case when observation_name = 'total_item_view' then observation_value end) as str_total_item_view,
    sum(case when observation_name = 'str_widget' then observation_value end) as str_widget,
    sum(case when observation_name = 'total_str_click' then observation_value end) as total_str_click,
    sum(case when observation_name = 'total_str_contact' then observation_value end) as total_str_contact,
    sum(case when observation_name = 'total_str_widget' then observation_value end) as total_str_widget
from str t
;
