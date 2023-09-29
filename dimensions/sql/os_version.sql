select os_version::varchar(64) as value
from dma.useragent_day
group by os_version
having sum(cnt_cookie) > 1000