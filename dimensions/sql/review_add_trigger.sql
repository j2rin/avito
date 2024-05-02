select distinct coalesce(review_add_trigger, 'null') as value
from dma.buyer_reviews_stream
where event_year is not null