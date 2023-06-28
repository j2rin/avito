select
    event_date,
    user_id,
    case when vertical_id!=-1 then vertical_id end as vertical_id,
    case when logical_category_id!=-1 then logical_category_id end as logical_category_id,
    less_1_month,
    is_asd,
    asd_user_group_id
from dma.new_pro_listers
where event_date::date between :first_date and :last_date
