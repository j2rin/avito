select cast(os_name as varchar(64)) as value
from dma.useragent_day
group by os_name
having sum(cnt_cookie) > 1000