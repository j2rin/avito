select distinct coalesce(buyer_review_form_type, 'null') as value
from dma.buyer_reviews_stream