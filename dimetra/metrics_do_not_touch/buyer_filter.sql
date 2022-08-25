create fact buyer_filter as
select
    t.event_date::date as __date__,
    *
from dma.o_buyer_filter t
;

create metrics buyer_filter as
select
    sum(btc_s) as btc_sess_filter,
    sum(contact_s) as contact_sess_filter,
    sum(iv_s) as iv_sess_filter,
    sum(search) as search_sess_filter
from buyer_filter t
;

create metrics buyer_filter_cookie as
select
    sum(case when btc_sess_filter > 0 then 1 end) as user_btc_sess_filter,
    sum(case when contact_sess_filter > 0 then 1 end) as user_contact_sess_filter,
    sum(case when iv_sess_filter > 0 then 1 end) as user_iv_sess_filter,
    sum(case when search_sess_filter > 0 then 1 end) as user_search_sess_filter
from (
    select
        cookie_id,
        sum(btc_s) as btc_sess_filter,
        sum(contact_s) as contact_sess_filter,
        sum(iv_s) as iv_sess_filter,
        sum(search) as search_sess_filter
    from buyer_filter t
    group by cookie_id
) _
;
