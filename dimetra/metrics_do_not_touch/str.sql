create fact str as
select
    t.event_date::date as __date__,
    *
from dma.vo_str t
;

create metrics str as
select
    sum(case when observation_name = 'item_off_str' then observation_value end) as item_off_str,
    sum(case when observation_name = 'items_with_str' then observation_value end) as items_with_str,
    sum(case when observation_name = 'str_booking_cost_nks_by_buyer' then observation_value end) as str_booking_cost_nks_by_buyer,
    sum(case when observation_name = 'str_booking_cost_nks_by_seller' then observation_value end) as str_booking_cost_nks_by_seller,
    sum(case when observation_name = 'str_booking_cost_old_flow_by_buyer' then observation_value end) as str_booking_cost_old_flow_by_buyer,
    sum(case when observation_name = 'str_booking_cost_old_flow_by_seller' then observation_value end) as str_booking_cost_old_flow_by_seller,
    sum(case when observation_name = 'str_bookings_approved_nks_by_buyer' then observation_value end) as str_bookings_approved_nks_by_buyer,
    sum(case when observation_name = 'str_bookings_approved_nks_by_seller' then observation_value end) as str_bookings_approved_nks_by_seller,
    sum(case when observation_name = 'str_bookings_by_buyer' then observation_value end) as str_bookings_by_buyer,
    sum(case when observation_name = 'str_bookings_by_seller' then observation_value end) as str_bookings_by_seller,
    sum(case when observation_name = 'str_bookings_comfirmed_nks_by_buyer' then observation_value end) as str_bookings_comfirmed_nks_by_buyer,
    sum(case when observation_name = 'str_bookings_comfirmed_nks_by_seller' then observation_value end) as str_bookings_comfirmed_nks_by_seller,
    sum(case when observation_name = 'str_bookings_comfirmed_old_flow_by_buyer' then observation_value end) as str_bookings_comfirmed_old_flow_by_buyer,
    sum(case when observation_name = 'str_bookings_comfirmed_old_flow_by_seller' then observation_value end) as str_bookings_comfirmed_old_flow_by_seller,
    sum(case when observation_name = 'str_bookings_expired_nks_by_buyer' then observation_value end) as str_bookings_expired_nks_by_buyer,
    sum(case when observation_name = 'str_bookings_expired_nks_by_seller' then observation_value end) as str_bookings_expired_nks_by_seller,
    sum(case when observation_name = 'str_bookings_nks_by_buyer' then observation_value end) as str_bookings_nks_by_buyer,
    sum(case when observation_name = 'str_bookings_nks_by_seller' then observation_value end) as str_bookings_nks_by_seller,
    sum(case when observation_name = 'str_bookings_old_flow_by_buyer' then observation_value end) as str_bookings_old_flow_by_buyer,
    sum(case when observation_name = 'str_bookings_old_flow_by_seller' then observation_value end) as str_bookings_old_flow_by_seller,
    sum(case when observation_name = 'str_bookings_paid_nks_by_buyer' then observation_value end) as str_bookings_paid_nks_by_buyer,
    sum(case when observation_name = 'str_bookings_paid_nks_by_seller' then observation_value end) as str_bookings_paid_nks_by_seller,
    sum(case when observation_name = 'str_bookings_paid_old_flow_by_buyer' then observation_value end) as str_bookings_paid_old_flow_by_buyer,
    sum(case when observation_name = 'str_bookings_paid_old_flow_by_seller' then observation_value end) as str_bookings_paid_old_flow_by_seller,
    sum(case when observation_name = 'str_bookings_unpaid_old_flow_by_buyer' then observation_value end) as str_bookings_unpaid_old_flow_by_buyer,
    sum(case when observation_name = 'str_bookings_unpaid_old_flow_by_seller' then observation_value end) as str_bookings_unpaid_old_flow_by_seller,
    sum(case when observation_name = 'str_deals_by_buyer' then observation_value end) as str_deals_by_buyer,
    sum(case when observation_name = 'str_deals_by_seller' then observation_value end) as str_deals_by_seller,
    sum(case when observation_name = 'str_deals_gmv_by_buyer' then observation_value end) as str_deals_gmv_by_buyer,
    sum(case when observation_name = 'str_deals_nks_by_buyer' then observation_value end) as str_deals_nks_by_buyer,
    sum(case when observation_name = 'str_deals_nks_by_seller' then observation_value end) as str_deals_nks_by_seller,
    sum(case when observation_name = 'str_deals_old_flow_by_buyer' then observation_value end) as str_deals_old_flow_by_buyer,
    sum(case when observation_name = 'str_deals_old_flow_by_seller' then observation_value end) as str_deals_old_flow_by_seller
from str t
;
