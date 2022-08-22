create fact support_comment as
select
    t.comment_create_date::date as __date__,
    *
from dma.vo_support_comment t
;

create metrics support_comment as
select
    sum(case when SatisfactionScore >= 4 then 1 end) as high_scored_comments,
    sum(case when SatisfactionScore = 1 then 1 end) as low_scored_comments,
    sum(1) as scored_comments
from support_comment t
;
