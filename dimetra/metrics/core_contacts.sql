create fact core_contacts as
select
    t.event_date::date as __date__,
    t.cookie_id as cookie,
    t.cookie_id,
    hash(t.cookie_id, t.logical_category_id) as cookie_logcat,
    t.event_date,
    t.is_buyer_new,
    hash(t.item_id, t.logical_category_id) as logcat_item,
    t.location_id,
    t.microcat_id,
    t.is_asd,
    t.platform_id
from dma.vo_core_contacts t
;

create metrics core_contacts_cookie as
select
    sum(case when cnt_contact > 0 then 1 end) as buyers_any
from (
    select
        cookie_id, cookie,
        sum(1) as cnt_contact
    from core_contacts t
    group by cookie_id, cookie
) _
;

create metrics core_contacts_cookie_logcat as
select
    sum(case when cnt_contact > 0 then 1 end) as buyers_canonical,
    sum(case when cnt_new_buyers > 0 then 1 end) as new_buyers,
    sum(case when cnt_returned_buyers > 0 then 1 end) as returned_buyers
from (
    select
        cookie_id, cookie_logcat,
        sum(1) as cnt_contact,
        sum(case when is_buyer_new = True then 1 end) as cnt_new_buyers,
        sum(case when is_buyer_new = False then 1 end) as cnt_returned_buyers
    from core_contacts t
    group by cookie_id, cookie_logcat
) _
;

create metrics core_contacts as
select
    sum(1) as cnt_contact,
    sum(case when is_buyer_new = True then 1 end) as cnt_new_buyers,
    sum(case when is_buyer_new = False then 1 end) as cnt_returned_buyers
from core_contacts t
;

create metrics core_contacts_logcat_item as
select
    sum(case when cnt_contact > 0 then 1 end) as contacts_canonical
from (
    select
        cookie_id, logcat_item,
        sum(1) as cnt_contact
    from core_contacts t
    group by cookie_id, logcat_item
) _
;
