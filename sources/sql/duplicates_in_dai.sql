with tmp as
(
    select
        *,
        SPLIT_PART(logical_category, '.', 1) as vertical
    from dma.duplicates_in_dai_buckets
)
select
    1 as _,
    event_date,
    q_items,
    all_dups_user,
    all_dups_cluster,
    geo_dups_user,
    geo_dups_cluster,
    geo_inter_dups_user,
    geo_inter_strong_dups_user,
    geo_inter_weak_dups_user,
    geo_inter_dups_cluster,
    geo_inter_strong_dups_cluster,
    geo_inter_weak_dups_cluster,
    geo_intra_dups_user,
    geo_intra_strong_dups_user,
    geo_intra_weak_dups_user,
    geo_intra_dups_cluster,
    geo_intra_strong_dups_cluster,
    geo_intra_weak_dups_cluster,
    multi_dups_user,
    multi_strong_dups_user,
    multi_weak_dups_user,
    multi_dups_cluster,
    multi_strong_dups_cluster,
    multi_weak_dups_cluster,
    -- Dimensions -----------------------------------------------------------------------------------------------------
    mv.vertical_id,
    mlc.logical_category_id
from tmp
join dma.m42_vertical mv on tmp.vertical = mv.vertical
join dma.m42_logical_category mlc on tmp.logical_category = mlc.logical_category
where event_date between :first_date and :last_date