select display_X::varchar(64) as value
from dma.useragent_day
group by display_X
having sum(cnt_cookie) > 1000