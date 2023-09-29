select app::varchar(64) as value
from dma.useragent_day
group by app
having sum(cnt_cookie) > 1000