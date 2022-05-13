create fact msh_banned_contacts as
select
    t.event_date::date as __date__,
    t.contacts,
    t.event_date,
    t.user_id
from dma.vo_msh_banned_contacts t
;

create metrics msh_banned_contacts as
select
    sum(contacts) as msh_banned_contacts
from msh_banned_contacts t
;
