select
    event_date,
    from_big_endian_64(xxhash64(cast(login as varbinary))) as user_hash,
    login as ldap_user,
    functional_line_name as functional_line,
    major_function_name as org_major_function,
    unit_id as org_unit_id,
    cluster_id as org_cluster_id,
    vertical_id as org_vertical_id,
    date_of_entry,
    date_of_dismissal
from dma.org_structure_full s
join dict.calendar c on c.event_date between s.date_of_entry and coalesce(s.date_of_dismissal, :last_date)
where record_priority = 1
and date_of_entry <= :last_date
and (date_of_dismissal >= :first_date or date_of_dismissal is null)