create fact delivery_user_toggle as
select
    t.event_date::date as __date__,
    t.event_date,
    t.isDeliveryActive,
    t.user_id
from dma.v_user_isDeliveryActive t
;

create metrics delivery_user_toggle as
select
    sum(case when isDeliveryActive = False then 1 end) as total_users_off_delivery_service,
    sum(case when isDeliveryActive = True then 1 end) as total_users_on_delivery_service
from delivery_user_toggle t
;

create metrics delivery_user_toggle_user_id as
select
    sum(case when total_users_off_delivery_service > 0 then 1 end) as users_off_delivery_service,
    sum(case when total_users_on_delivery_service > 0 then 1 end) as users_on_delivery_service
from (
    select
        user_id, user_id,
        sum(case when isDeliveryActive = False then 1 end) as total_users_off_delivery_service,
        sum(case when isDeliveryActive = True then 1 end) as total_users_on_delivery_service
    from delivery_user_toggle t
    group by user_id, user_id
) _
;
