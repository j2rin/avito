select  split_part(slug, '_', 2) as value
from    dds.s_tariff_slug
where   split_part(slug, '_', 2) is not null
group by 1