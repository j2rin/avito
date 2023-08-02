select
    event_date,
    ldap_user,
    event_hash,
    hash(ldap_user) as user_hash,
    hash(ldap_user, event_date) as user_date_hash,
    0 as user_id, -- dummy user_id, пока мы требуем его в системе
    cast(metric as int) as picked_metric_id
from (
    select
        date(dtm) as event_date,
        ldap_user,
        hash(uuid) as event_hash,
        explode(string_to_array(JsonLookup(m42_filters, 'metric'))) over(partition by date(dtm), ldap_user, hash(uuid)) as (ind, metric)
    from dwhcs.clickstream_data_platform
    where date(dtm) between :first_date and :last_date
        and m42_filters is not null
        and eid = 6287
) _
