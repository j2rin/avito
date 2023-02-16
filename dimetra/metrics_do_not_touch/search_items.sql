create fact search_items as
select
    t.event_date::date as __date__,
    *
from dma.vo_search_items t
;

create metrics search_items as
select
    sum(case when eventtype_id = 109161500001 then items_count end) as cnt_rec_items_i2i,
    sum(case when eventtype_id = 30204750001 then items_count end) as cnt_rec_items_u2i,
    sum(case when eventtype_id = 109161500001 then score end) as cnt_rec_score_i2i,
    sum(case when eventtype_id = 30204750001 then score end) as cnt_rec_score_u2i,
    sum(case when eventtype_id = 10 then freshness end) as cnt_serp_freshness,
    sum(case when eventtype_id = 10 then items_count end) as cnt_serp_items,
    sum(case when eventtype_id = 30204750001 then sellers_count end) as seller_buyer_pair_with_rec_u2i,
    sum(case when eventtype_id = 10 then sellers_count end) as seller_buyer_pair_with_search,
    sum(sellers_count) as seller_buyer_pair_with_show,
    sum(case when eventtype_id = 30204750001 and item_engines & 1 > 0 then items_count end) as show_u2i_collab,
    sum(case when eventtype_id = 30204750001 and item_engines & 16 > 0 then items_count end) as show_u2i_graph,
    sum(case when eventtype_id = 30204750001 and item_engines & 8 > 0 then items_count end) as show_u2i_similars,
    sum(case when eventtype_id = 30204750001 and item_engines & 2 > 0 then items_count end) as show_u2i_user2vec
from search_items t
;
