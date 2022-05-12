create fact public_profile as
select
    t.event_date as __date__,
    t.cookie_id as cookie,
    t.cookie_id,
    t.event_date,
    t.public_profile_active_items_paginations,
    t.public_profile_closed_items_paginations,
    t.public_profile_closed_tabs,
    t.public_profile_unique_views,
    t.public_profile_views
from dma.vo_public_profile t
;

create metrics public_profile as
select
    sum(public_profile_closed_tabs) as cnt_public_profile_closed_tabs,
    sum(public_profile_active_items_paginations) as public_profile_active_items_paginations,
    sum(public_profile_closed_items_paginations) as public_profile_closed_items_paginations,
    sum(public_profile_unique_views) as public_profile_unique_views,
    sum(public_profile_views) as public_profile_views
from public_profile t
;

create metrics public_profile_cookie as
select
    sum(case when public_profile_active_items_paginations > 0 then 1 end) as public_profile_active_items_paginations_proportion,
    sum(case when public_profile_closed_items_paginations > 0 then 1 end) as public_profile_closed_items_paginations_proportion,
    sum(case when cnt_public_profile_closed_tabs > 0 then 1 end) as public_profile_closed_tabs_proportion,
    sum(case when public_profile_views > 0 then 1 end) as public_profile_views_proportion
from (
    select
        cookie_id, cookie,
        sum(public_profile_closed_tabs) as cnt_public_profile_closed_tabs,
        sum(public_profile_active_items_paginations) as public_profile_active_items_paginations,
        sum(public_profile_closed_items_paginations) as public_profile_closed_items_paginations,
        sum(public_profile_views) as public_profile_views
    from public_profile t
    group by cookie_id, cookie
) _
;
