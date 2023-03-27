create fact pageviews as
select
    t.event_date::date as __date__,
    t.pv_count as events_count,
    t.iv_count as itemviews_count,
    hash(t.cookie_id, t.event_date)                        as cookie_day_hash,
    hash(t.cookie_id, date_trunc('month', t.event_date))   as cookie_month_hash,
    user_id as _user_id_dim,
    *
from dma.dau_source t
participant_columns(cookie_id)
;
