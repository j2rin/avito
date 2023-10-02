select display_Y::varchar(64) as value
from dma.useragent_day
group by display_Y
having sum(cnt_cookie) > 1000