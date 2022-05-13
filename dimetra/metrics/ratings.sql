create fact ratings as
select
    t.event_date::date as __date__,
    t.cookie_id,
    t.event_date,
    t.observation_name,
    t.observation_value,
    t.participant_id as participant
from dma.vo_ratings t
;

create metrics ratings_participant as
select
    sum(case when contacts_on_rating_1 > 0 then 1 end) as buyers_on_rating_1,
    sum(case when contacts_on_rating_2 > 0 then 1 end) as buyers_on_rating_2,
    sum(case when contacts_on_rating_3 > 0 then 1 end) as buyers_on_rating_3,
    sum(case when contacts_on_rating_4 > 0 then 1 end) as buyers_on_rating_4,
    sum(case when contacts_on_rating_5 > 0 then 1 end) as buyers_on_rating_5,
    sum(case when reviews_stage_deal_happened > 0 then 1 end) as user_reviews_stage_deal_happened,
    sum(case when reviews_added > 0 then 1 end) as users_reviews_added
from (
    select
        cookie_id, participant,
        sum(case when observation_name = 'contacts_on_rating_1' then observation_value end) as contacts_on_rating_1,
        sum(case when observation_name = 'contacts_on_rating_2' then observation_value end) as contacts_on_rating_2,
        sum(case when observation_name = 'contacts_on_rating_3' then observation_value end) as contacts_on_rating_3,
        sum(case when observation_name = 'contacts_on_rating_4' then observation_value end) as contacts_on_rating_4,
        sum(case when observation_name = 'contacts_on_rating_5' then observation_value end) as contacts_on_rating_5,
        sum(case when observation_name = 'reviews_added' then observation_value end) as reviews_added,
        sum(case when observation_name = 'reviews_stage_deal_happened' then observation_value end) as reviews_stage_deal_happened
    from ratings t
    group by cookie_id, participant
) _
;

create metrics ratings as
select
    sum(case when observation_name = 'reviews_score_sum' then observation_value end) as cnt_reviews_score_sum,
    sum(case when observation_name = 'search_items' then observation_value end) as cnt_s_items,
    sum(case when observation_name = 'search_items_with_rating' then observation_value end) as cnt_s_items_with_rating,
    sum(case when observation_name = 'searches_with_rating' then observation_value end) as cnt_s_with_rating,
    sum(case when observation_name in ('contacts_on_rating_1', 'contacts_on_rating_2', 'contacts_on_rating_3', 'contacts_on_rating_4', 'contacts_on_rating_5') then observation_value end) as contacts_on_rating,
    sum(case when observation_name = 'contacts_on_rating_1' then observation_value end) as contacts_on_rating_1,
    sum(case when observation_name = 'contacts_on_rating_2' then observation_value end) as contacts_on_rating_2,
    sum(case when observation_name = 'contacts_on_rating_3' then observation_value end) as contacts_on_rating_3,
    sum(case when observation_name = 'contacts_on_rating_4' then observation_value end) as contacts_on_rating_4,
    sum(case when observation_name = 'contacts_on_rating_5' then observation_value end) as contacts_on_rating_5,
    sum(case when observation_name = 'contacts_with_review_list_view' then observation_value end) as contacts_with_review_list_view,
    sum(case when observation_name = 'itemviews_on_rating_1' then observation_value end) as item_views_on_rating_1,
    sum(case when observation_name = 'itemviews_on_rating_2' then observation_value end) as item_views_on_rating_2,
    sum(case when observation_name = 'itemviews_on_rating_3' then observation_value end) as item_views_on_rating_3,
    sum(case when observation_name = 'itemviews_on_rating_4' then observation_value end) as item_views_on_rating_4,
    sum(case when observation_name = 'itemviews_on_rating_5' then observation_value end) as item_views_on_rating_5,
    sum(case when observation_name = 'active_items_with_rating' then observation_value end) as items_with_rating,
    sum(case when observation_name = 'reviews_added' then observation_value end) as reviews_added,
    sum(case when observation_name = 'reviews_stage_deal_happened' then observation_value end) as reviews_stage_deal_happened
from ratings t
;
