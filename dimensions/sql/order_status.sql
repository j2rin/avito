select distinct coalesce(order_status, 'null') as value
from dma.buyer_reviews_stream