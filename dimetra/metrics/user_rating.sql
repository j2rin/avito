create fact user_rating as
select
    t.event_date::date as __date__,
    t.event_date,
    t.observation_name,
    t.observation_value,
    t.user_id
from dma.vo_user_rating t
;

create metrics user_rating as
select
    sum(case when observation_name = 'seller_has_rating_any' then observation_value end) as sellers_with_rating,
    sum(case when observation_name = 'seller_has_rating_1' then observation_value end) as sellers_with_rating_1,
    sum(case when observation_name = 'seller_has_rating_2' then observation_value end) as sellers_with_rating_2,
    sum(case when observation_name = 'seller_has_rating_3' then observation_value end) as sellers_with_rating_3,
    sum(case when observation_name = 'seller_has_rating_4' then observation_value end) as sellers_with_rating_4,
    sum(case when observation_name = 'seller_has_rating_5' then observation_value end) as sellers_with_rating_5
from user_rating t
;
