select vendor::varchar(64) as value
from dma.useragent_day
group by vendor
having sum(cnt_cookie) > 1000