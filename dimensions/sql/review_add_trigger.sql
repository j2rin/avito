select distinct coalesce(review_add_trigger, 'null') as value
from dma.buyer_reviews_stream