select
    _batch, _partition,
    u, eid, event_hash, event_date,
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
    bitShiftLeft(toUInt64(length(metro_list) > 0), 0) +
    bitShiftLeft(toUInt64(length(district_list) > 0), 1) +
    bitShiftLeft(toUInt64(srd <> '' and srd <> '0'), 3) +
    bitShiftLeft(toUInt64(onmap > 0), 4) +
    bitShiftLeft(toUInt64(d > 0), 5) +
    bitShiftLeft(toUInt64(ssid > 0), 6) +
    bitShiftLeft(toUInt64(sid > 0), 7) + 
    bitShiftLeft(toUInt64(length(params) > 2), 8) +
    bitShiftLeft(toUInt64(pmin > 0 or pmax > 0), 9) +
    bitShiftLeft(toUInt64(search_features), 10) +
    bitShiftLeft(toUInt64(is_marketplace), 31) +
    bitShiftLeft(toUInt64(marketplace_count > 0), 32) +
    bitShiftLeft(toUInt64(local_priority), 33) +
    bitShiftLeft(toUInt64(multi_loc_cnt > 0), 34) +
    -- Поиск по каталогу новостроек (ЖК):
    bitShiftLeft(toUInt64(catalog_jk_attribute = 1), 35) +
    -- Поиск на карточке новостройки (ЖК):
    bitShiftLeft(toUInt64(catalog_jk_attribute = 2), 36) + 
    -- Поиск с предзаполненными и не модифицированными фильтрами:
    bitShiftLeft(toUInt64(saved_filters_search_id = 1), 37) +
    -- Поиск с предзаполненными и модифицированными фильтрами:
    bitShiftLeft(toUInt64(saved_filters_search_id = 2), 38) +
    -- Флаг по типу отображения, поле vid, поле займет 4 бита!, т.е. следующий с 43!!!
    bitShiftLeft(toUInt64(vid%16), 39) +
    -- Флаг для подборок(!) избранного
    bitShiftLeft(toUInt64(length(favlist) > 0), 43) +
    -- Флаг поисков с фильтром Avito Mall
    bitShiftLeft(toUInt64(JSONHas(params, '147740')), 44)
    as search_flags,
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
