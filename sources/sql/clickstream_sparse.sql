select
    _batch, _partition,
    xxHash64(coalesce(u, '')) as u, eid, event_hash, event_date,
    business_platform,
    event_timestamp,
    app_state,
    uid,
    iid,
    fps_threshold,
    image_error,
    x,
    ios_network_error_type,
    ios_network_error_subtype,
    new_exception_id,
    onmap,
    search_features,
    toUInt32(if(limit > 0, offset, 0) / if(limit > 0, limit, 1)) as page_no,
    position as rec_position,
    if(x != '' and __x_q = '',       q,        __x_q)        as __x_q,
    if(x != '' and __x_eid = 0,      eid,      __x_eid)      as __x_eid,
    if(x != '' and __x_engine = '',  engine,   __x_engine)   as _x__engine,
    if(x != '' and __x_mcid = 0,     mcid,     __x_mcid)     as __x_mcid,
    if(x != '' and __x_lid = 0,      lid,      __x_lid)      as __x_lid,
    if(x != '' and __x_position = 0, position, __x_position) as __x_position,
    safedeal_services
from dwh.clickstream_sparse_local
where event_date between date(:first_date) and date(:last_date)
