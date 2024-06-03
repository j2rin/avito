select
    event_no,
    event_date,
    event_timestamp,
    cookie_id,
    user_id,
    location_id,
    platform_id,
    platform,
    item_id,
    eventtype_id,
    eid as eventtype_ext,
    from_page,
    from_page as x_from_page,
    is_human,
    region,
    event_count,
    case 
        when from_page = 'tinkoff' and eid = 4498 then 'enter_tinkoff'
        when from_page = 'autobrokerSber' and eid = 4498 then 'enter_sber'
    else 'unknown' end flag
from dma.c2cloans_clickstream
where
    eid in (4496, 9651, 4801, 4498, 9752, 4502, 9822)
    and cast(event_date as date) >= cast('2023-11-01' as date)
    and cast(event_date as date) between :first_date and :last_date
--     and event_month between date_trunc('month', :first_date) and date_trunc('month', :last_date) --@trino
    and from_page in (
        'c2c_item_card', 'c2c_usp_banner',
        'autobrokerSber', 'tinkoff', 'blankWork',
        'single_point_item_card', 'single_point_tinkoff', 'single_point_sber',
        'single_banner', 'single_banner_tinkoff', 'single_banner_sber'
    )