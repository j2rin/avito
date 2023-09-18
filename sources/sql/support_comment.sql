select comment_create_date,
	   comment_id,
       SatisfactionScore,
       line
from dma.comment_satisfaction_scores
where cast(comment_create_date as date) between :first_date and :last_date
