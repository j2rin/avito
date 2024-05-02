select cast(os_name as varchar(64)) as value
from dma.useragent_day
where event_year is not null
group by os_name
having sum(cnt_cookie) > 1000