select
    date(dtm) as event_date,
    eid,
    src_id,
    version,
    ldap_user,
    hash(ldap_user) as user_hash,
    hash(ldap_user, date(dtm)) as user_date_hash,
    0 as user_id, -- dummy user_id, пока мы требуем его в системе
    uuid,
    m42_filters,
    event_time,
    url,
    properties
from dwhcs.clickstream_data_platform
where date(dtm) between :first_date and :last_date
