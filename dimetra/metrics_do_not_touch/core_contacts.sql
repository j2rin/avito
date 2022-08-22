create fact core_contacts as
select
    t.event_date::date as __date__,
    *
from dma.vo_core_contacts_dimetra t
;

create metrics core_contacts_cookie as
select
    sum(case when cnt_contact > 0 then 1 end) as buyers_any
from (
    select
        cookie_id,
        sum(1) as cnt_contact
    from core_contacts t
    group by cookie_id
) _
;

create metrics core_contacts_cookie_logcat as
select
    sum(case when cnt_contact > 0 then 1 end) as buyers_canonical,
    sum(case when cnt_new_buyers > 0 then 1 end) as new_buyers,
    sum(case when cnt_returned_buyers > 0 then 1 end) as returned_buyers
from (
    select
        cookie_id, logical_category_id,
        sum(1) as cnt_contact,
        sum(case when is_buyer_new = True then 1 end) as cnt_new_buyers,
        sum(case when is_buyer_new = False then 1 end) as cnt_returned_buyers
    from core_contacts t
    group by cookie_id, logical_category_id
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
        cookie_id, item_id, logical_category_id,
        sum(1) as cnt_contact
    from core_contacts t
    group by cookie_id, item_id, logical_category_id
) _
;
