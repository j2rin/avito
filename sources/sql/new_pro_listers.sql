select
    event_date,
    user_id,
    vertical_id,
    logical_category_id,
    less_1_month,
    is_asd,
    asd_user_group_id
from dma.new_pro_listers
where event_date::date between :first_date and :last_date
    and logical_category_id != -1
    and vertical_id != -1
