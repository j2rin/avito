create fact reviews as
select
    t.event_date as __date__,
    t.cookie_id,
    t.event_date,
    t.score,
    t.stage,
    t.user_id as user
from dma.vo_reviews t
;

create metrics reviews as
select
    sum(1) as all_reviews_added,
    sum(score) as cnt_all_reviews_score_sum,
    sum(case when stage in (1, 2) then score end) as cnt_rating_reviews_score_sum,
    sum(case when stage in (1, 2) then 1 end) as rating_reviews_added,
    sum(case when stage = 2 then 1 end) as reviews_stage_deal_canceled,
    sum(case when stage = 1 then 1 end) as reviews_stage_deal_happened_new,
    sum(case when stage = 3 then 1 end) as reviews_stage_no_agreement,
    sum(case when stage = 4 then 1 end) as reviews_stage_no_communication
from reviews t
;

create metrics reviews_user as
select
    sum(case when all_reviews_added > 0 then 1 end) as user_all_reviews_added,
    sum(case when rating_reviews_added > 0 then 1 end) as user_rating_reviews_added,
    sum(case when reviews_stage_deal_canceled > 0 then 1 end) as user_reviews_stage_deal_canceled,
    sum(case when reviews_stage_deal_happened_new > 0 then 1 end) as user_reviews_stage_deal_happened_new,
    sum(case when reviews_stage_no_agreement > 0 then 1 end) as user_reviews_stage_no_agreement,
    sum(case when reviews_stage_no_communication > 0 then 1 end) as user_reviews_stage_no_communication
from (
    select
        cookie_id, user,
        sum(1) as all_reviews_added,
        sum(case when stage in (1, 2) then 1 end) as rating_reviews_added,
        sum(case when stage = 2 then 1 end) as reviews_stage_deal_canceled,
        sum(case when stage = 1 then 1 end) as reviews_stage_deal_happened_new,
        sum(case when stage = 3 then 1 end) as reviews_stage_no_agreement,
        sum(case when stage = 4 then 1 end) as reviews_stage_no_communication
    from reviews t
    group by cookie_id, user
) _
;
