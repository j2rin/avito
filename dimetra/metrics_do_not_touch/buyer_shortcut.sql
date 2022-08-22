create fact buyer_shortcut as
select
    t.event_date::date as __date__,
    *
from dma.o_buyer_shortcut t
;

create metrics buyer_shortcut as
select
    sum(btc_s) as btc_sess_shortcut,
    sum(contact_s) as contact_sess_shortcut,
    sum(iv_s) as iv_sess_shortcut,
    sum(search) as search_sess_shortcut
from buyer_shortcut t
;

create metrics buyer_shortcut_cookie as
select
    sum(case when btc_sess_shortcut > 0 then 1 end) as user_btc_sess_shortcut,
    sum(case when contact_sess_shortcut > 0 then 1 end) as user_contact_sess_shortcut,
    sum(case when iv_sess_shortcut > 0 then 1 end) as user_iv_sess_shortcut,
    sum(case when search_sess_shortcut > 0 then 1 end) as user_search_sess_shortcut
from (
    select
        cookie_id,
        sum(btc_s) as btc_sess_shortcut,
        sum(contact_s) as contact_sess_shortcut,
        sum(iv_s) as iv_sess_shortcut,
        sum(search) as search_sess_shortcut
    from buyer_shortcut t
    group by cookie_id
) _
;
