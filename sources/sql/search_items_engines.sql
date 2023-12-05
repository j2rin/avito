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
    score
from dma.search_items_engines
where cast(event_date as date) between :first_date and :last_date

