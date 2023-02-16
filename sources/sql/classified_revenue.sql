select *
from dma.v_paying_user_report_full
where event_date::date between :first_date and :last_date
