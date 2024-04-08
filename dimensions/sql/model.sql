select cast(model as varchar(64)) as value
from dma.useragent_day
group by model
having sum(cnt_cookie) > 1000