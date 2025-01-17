select
    date(dtm) as event_date,
    eid,
    src_id,
    version,
    ldap_user,
    hash(ldap_user) as user_hash,
    hash(ldap_user, date(dtm)) as user_date_hash,
    uuid,
    m42_filters,
    event_time,
    url,
    properties,
    case
        when eid in (9248, 9249) then maplookup(mapjsonextractor(properties), 'field')
    else null end as properties_field
from dwhcs.clickstream_data_platform
where date(dtm) between :first_date and :last_date
