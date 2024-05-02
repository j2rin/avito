select distinct coalesce(page_from, 'null') as value
from dma.buyer_reviews_stream
where event_year is not null