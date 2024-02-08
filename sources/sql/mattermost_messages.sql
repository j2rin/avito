select
    create_at as message_ts,
    root_id is null as is_root,
    channel,
    user_name as ldap_user,
    from_big_endian_64(xxhash64(cast(coalesce(user_name, '') as varbinary))) as user_hash,
    message,
    regexp_like(lower(cast(message as varchar(32500))), '\b(слой|слоя|слою|слоем|слое|слои|слоев|слоям|слоями|слоях)\b') as is_subject_layer
from DMA.mattermost_messages
where date(create_at) between date(:first_date) and date(:last_date)
