select distinct
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
    clc.vertical_id,
    clc.logical_category_id
from dma.duplicates_in_dai_buckets didb
join dma.current_logical_categories clc on didb.logical_category = clc.logical_category
where true 
    and event_date between :first_date and :last_date
    -- and event_year between date_trunc('year', date(:first_date)) and date_trunc('year', date(:last_date)) -- @trino