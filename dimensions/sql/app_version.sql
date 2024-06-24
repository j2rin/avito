SELECT 
    CASE
        WHEN app_version IS NULL THEN NULL
        ELSE cast(rtrim(rtrim(format('%f', app_version), '0'), '.') AS varchar(64))
    END AS value
from dma.useragent_day
where event_year is not null
group by app_version
having sum(cnt_cookie) > 1000