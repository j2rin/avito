create fact core_contacts as
select
    t.event_date::date as __date__,
    user_id as _user_id_dim,
    *
from dma.vo_core_contacts_dimetra t
participant_columns(cookie_id)
;