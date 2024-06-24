SELECT
    CASE
        WHEN browser_version IS NULL THEN NULL
        ELSE cast(rtrim(rtrim(format('%f', browser_version), '0'), '.') AS varchar(64))
    END AS value
from dma.useragent_day
where event_year is not null
group by browser_version
having sum(cnt_cookie) > 1000