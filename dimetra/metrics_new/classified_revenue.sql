create fact classified_revenue as
select
    t.event_date::date as __date__,
    *
from dma.v_paying_user_report_full_dimetra t
participant_columns(user_id)
;