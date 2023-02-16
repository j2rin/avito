create fact model_rating_stream as
select
    t.event_date::date as __date__,
    *
from dma.vo_model_rating_stream t
;

create metrics model_rating_stream as
select
    sum(case when rating in (1, 2, 3, 4, 5) then contacts end) as contacts_on_model_rating,
    sum(case when rating = 1 then contacts end) as contacts_on_model_rating_1,
    sum(case when rating = 2 then contacts end) as contacts_on_model_rating_2,
    sum(case when rating = 3 then contacts end) as contacts_on_model_rating_3,
    sum(case when rating = 4 then contacts end) as contacts_on_model_rating_4,
    sum(case when rating = 5 then contacts end) as contacts_on_model_rating_5,
    sum(case when rating not in (1, 2, 3, 4, 5) then contacts end) as contacts_wo_model_rating,
    sum(case when rating in (1, 2, 3, 4, 5) then item_views end) as item_views_on_model_rating,
    sum(case when rating = 1 then item_views end) as item_views_on_model_rating_1,
    sum(case when rating = 2 then item_views end) as item_views_on_model_rating_2,
    sum(case when rating = 3 then item_views end) as item_views_on_model_rating_3,
    sum(case when rating = 4 then item_views end) as item_views_on_model_rating_4,
    sum(case when rating = 5 then item_views end) as item_views_on_model_rating_5,
    sum(case when rating not in (1, 2, 3, 4, 5) then item_views end) as item_views_wo_model_rating
from model_rating_stream t
;
