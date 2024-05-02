select cast(type_device as varchar(64)) as value
from dma.useragent_day
where event_year is not null
group by type_device
having sum(cnt_cookie) > 1000