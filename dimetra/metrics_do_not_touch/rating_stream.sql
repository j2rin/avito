create fact rating_stream as
select
    t.event_date::date as __date__,
    *
from dma.vo_rating_stream t
;

create metrics rating_stream_cookie as
select
    sum(case when contacts_on_rating > 0 then 1 end) as buyers_on_rating,
    sum(case when contacts_on_rating_1 > 0 then 1 end) as buyers_on_rating_1,
    sum(case when contacts_on_rating_2 > 0 then 1 end) as buyers_on_rating_2,
    sum(case when contacts_on_rating_3 > 0 then 1 end) as buyers_on_rating_3,
    sum(case when contacts_on_rating_4 > 0 then 1 end) as buyers_on_rating_4,
    sum(case when contacts_on_rating_5 > 0 then 1 end) as buyers_on_rating_5
from (
    select
        cookie_id,
        sum(case when rating in (1, 2, 3, 4, 5) then contacts end) as contacts_on_rating,
        sum(case when rating = 1 then contacts end) as contacts_on_rating_1,
        sum(case when rating = 2 then contacts end) as contacts_on_rating_2,
        sum(case when rating = 3 then contacts end) as contacts_on_rating_3,
        sum(case when rating = 4 then contacts end) as contacts_on_rating_4,
        sum(case when rating = 5 then contacts end) as contacts_on_rating_5
    from rating_stream t
    group by cookie_id
) _
;

create metrics rating_stream as
select
    sum(case when rating in (1, 2, 3, 4, 5) then contacts end) as contacts_on_rating,
    sum(case when rating = 1 then contacts end) as contacts_on_rating_1,
    sum(case when rating = 2 then contacts end) as contacts_on_rating_2,
    sum(case when rating = 3 then contacts end) as contacts_on_rating_3,
    sum(case when rating = 4 then contacts end) as contacts_on_rating_4,
    sum(case when rating = 5 then contacts end) as contacts_on_rating_5,
    sum(contacts_with_review_list_view) as contacts_with_review_list_view,
    sum(case when rating in (1, 2, 3, 4, 5) then item_views end) as item_views_on_rating,
    sum(case when rating = 1 then item_views end) as item_views_on_rating_1,
    sum(case when rating = 2 then item_views end) as item_views_on_rating_2,
    sum(case when rating = 3 then item_views end) as item_views_on_rating_3,
    sum(case when rating = 4 then item_views end) as item_views_on_rating_4,
    sum(case when rating = 5 then item_views end) as item_views_on_rating_5
from rating_stream t
;
