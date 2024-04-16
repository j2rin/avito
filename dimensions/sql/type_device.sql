select cast(type_device as varchar(64)) as value
from dma.useragent_day
group by type_device
having sum(cnt_cookie) > 1000