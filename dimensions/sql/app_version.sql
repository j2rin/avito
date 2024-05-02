select cast(app_version as varchar(64)) as value
from dma.useragent_day
where event_year is not null
group by app_version
having sum(cnt_cookie) > 1000