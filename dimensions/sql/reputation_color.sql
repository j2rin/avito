select distinct reputation_color as value
from dma.user_reputation
where event_month is not null
