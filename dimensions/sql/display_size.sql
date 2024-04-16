select cast(display_size as varchar(64)) as value
from dma.useragent_day
group by display_size
having sum(cnt_cookie) > 1000