create fact str_by_cookies as
select
    t.event_date::date as __date__,
    *
from dma.vo_str t
;

create metrics str_by_cookies as
select
    sum(case when observation_name = 'str_click' then observation_value end) as str_click,
    sum(case when observation_name = 'str_contact' then observation_value end) as str_contact,
    sum(case when observation_name = 'item_view' then observation_value end) as str_item_view,
    sum(case when observation_name = 'total_item_view' then observation_value end) as str_total_item_view,
    sum(case when observation_name = 'str_widget' then observation_value end) as str_widget,
    sum(case when observation_name = 'total_str_click' then observation_value end) as total_str_click,
    sum(case when observation_name = 'total_str_contact' then observation_value end) as total_str_contact,
    sum(case when observation_name = 'total_str_widget' then observation_value end) as total_str_widget
from str_by_cookies t
;
