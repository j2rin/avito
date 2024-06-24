SELECT
    CASE
        WHEN display_size IS NULL THEN NULL
        ELSE cast(rtrim(rtrim(format('%f', display_size), '0'), '.') AS varchar(64))
    END AS value
from dma.useragent_day
where event_year is not null
group by display_size
having sum(cnt_cookie) > 1000