select cast(os_version as varchar(64)) as value
from dma.useragent_day
group by os_version
having sum(cnt_cookie) > 1000