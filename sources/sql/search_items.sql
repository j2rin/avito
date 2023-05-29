select
    event_date,
    cookie_id,
    platform_id,
    eventtype_id,
    item_engines,
    vertical_id,
    logical_category_id,
    category_id,
    subcategory_id,
    region_id,
    items_count,
    score,
    freshness,
    sellers_count,
    items_dedup_count,
    items_grouped_count
from dma.vo_search_items
where event_date::date between :first_date and :last_date

