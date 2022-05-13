create fact rating_stream as
select
    t.event_date::date as __date__,
    t.contacts,
    t.contacts_with_review_list_view,
    t.cookie_id as cookie,
    t.cookie_id,
    t.event_date,
    t.item_views,
    t.rating
from dma.vo_rating_stream t
;

create metrics rating_stream_cookie as
select
    sum(case when contacts_on_rating_new > 0 then 1 end) as buyers_on_rating,
    sum(case when contacts_on_rating_1_new > 0 then 1 end) as buyers_on_rating_1_new,
    sum(case when contacts_on_rating_2_new > 0 then 1 end) as buyers_on_rating_2_new,
    sum(case when contacts_on_rating_3_new > 0 then 1 end) as buyers_on_rating_3_new,
    sum(case when contacts_on_rating_4_new > 0 then 1 end) as buyers_on_rating_4_new,
    sum(case when contacts_on_rating_5_new > 0 then 1 end) as buyers_on_rating_5_new
from (
    select
        cookie_id, cookie,
        sum(case when rating = 1 then contacts end) as contacts_on_rating_1_new,
        sum(case when rating = 2 then contacts end) as contacts_on_rating_2_new,
        sum(case when rating = 3 then contacts end) as contacts_on_rating_3_new,
        sum(case when rating = 4 then contacts end) as contacts_on_rating_4_new,
        sum(case when rating = 5 then contacts end) as contacts_on_rating_5_new,
        sum(case when rating in (1, 2, 3, 4, 5) then contacts end) as contacts_on_rating_new
    from rating_stream t
    group by cookie_id, cookie
) _
;

create metrics rating_stream as
select
    sum(case when rating = 1 then contacts end) as contacts_on_rating_1_new,
    sum(case when rating = 2 then contacts end) as contacts_on_rating_2_new,
    sum(case when rating = 3 then contacts end) as contacts_on_rating_3_new,
    sum(case when rating = 4 then contacts end) as contacts_on_rating_4_new,
    sum(case when rating = 5 then contacts end) as contacts_on_rating_5_new,
    sum(case when rating in (1, 2, 3, 4, 5) then contacts end) as contacts_on_rating_new,
    sum(contacts_with_review_list_view) as contacts_with_review_list_view_new,
    sum(case when rating in (1, 2, 3, 4, 5) then item_views end) as item_views_on_rating,
    sum(case when rating = 1 then item_views end) as item_views_on_rating_1_new,
    sum(case when rating = 2 then item_views end) as item_views_on_rating_2_new,
    sum(case when rating = 3 then item_views end) as item_views_on_rating_3_new,
    sum(case when rating = 4 then item_views end) as item_views_on_rating_4_new,
    sum(case when rating = 5 then item_views end) as item_views_on_rating_5_new
from rating_stream t
;
