create fact buyer_stream as
select
    t.event_date::date as                                                                                                   __date__,
    CASE
        WHEN item_x_type % 2 = 0 and x_eid = 300 and page_no = 0 and item_rnk >= 0 and item_rnk <= 3 then 'serp_top3'
        WHEN item_x_type % 2 = 0 and x_eid = 300 and page_no = 0 and item_rnk >= 4 and item_rnk <= 10 then 'serp_top10'
        WHEN item_x_type % 2 = 0 and x_eid = 300 and page_no = 0 and item_rnk >= 11 and item_rnk <= 30 then 'serp_top30'
        WHEN x_eid = 300 and item_x_type % 2 = 0 then 'serp'
        WHEN x_eid = 2437 and item_x_type % 2 = 0 then 'rec_u2i'
        WHEN x_eid in (2012, 2309) and item_x_type % 2 = 0 then 'rec_i2i'
        ELSE 'other' END
    AS                                                                                                                      last_click_source,
    CASE
        WHEN item_x_type % 2 = 0 and query_id is not null and x_eid = 300 then 'text'
        WHEN item_x_type % 2 = 0 and x_eid = 300 and (search_flags & 768 > 0) then 'param'
        ELSE 'other' END
    AS                                                                                                                      search_type,
    CASE WHEN query_id is not null then 'q' else '' end as q,
    coalesce(item_count,0) as                                                                                               item_count,
    coalesce(base_item_count,0) as                                                                                          base_item_count,
    item_x_type % 2 as item_x_type,
    CASE WHEN x_eid is not null then coalesce(search_flags,0) end as                                                        search_flags,
    coalesce(item_flags,0) as item_flags,
    coalesce(other_flags,0) as other_flags,
    is_human_dev                                              as                                                            is_human,
    search_radius::varchar                                    as                                                            search_radius,
    hash(item_id, x, eid)                              as                                                                   item_x,
    hash(location_id, session_no, microcat_id)         as                                                                   location_session_microcat,
    CASE WHEN eid in (401, 2574, 2732) then 1 WHEN eid = 402 then -1 end as                                                 favorites_net,
    rec_engine_id                                             as                                                            x_rec_engine_id,
    ((case when ss.x_eid is not null then coalesce(ss.search_flags, 0) end & 16) > 0)::int as                               onmap,
    *
from dma.buyer_stream t
;