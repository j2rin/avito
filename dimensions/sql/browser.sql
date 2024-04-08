select cast(browser as varchar(64)) as value
from dma.useragent_day
group by browser
having sum(cnt_cookie) > 1000