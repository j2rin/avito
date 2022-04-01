create fact buyer_stream as select
    s.cookie_id as cookie,
    s.event_date::date as _date,
    s.eid as eid,
    case when eid in (303, 856, 857, 2581, 3005, 3461, 4066, 4198, 4675) then 1 else 0 end as is_eid_contact
from
dma.buyer_stream s;

create metrics contacts as
select countif(is_eid_contact) as contacts,
countif(case when is_eid_contact = 0 then 1 else 0 end) as contacts_inverse
from buyer_stream;
