create fact bs_first_click as
select
    t.event_date::date as __date__,
    *
from dma.bs_first_click t
;

create metrics bs_first_click as
select
    sum(case when eid = 'c' and x_eid = 300 then 1 end) as cnt_first_c_s,
    sum(case when eid = 'c' and x_eid = 300 then item_rnk end) as cnt_first_c_s_rnk,
    sum(case when eid = 'c' and x_eid = 2012 then 1 end) as cnt_first_c_u2i,
    sum(case when eid = 'c' and x_eid = 2012 then item_rnk end) as cnt_first_c_u2i_rnk,
    sum(case when eid = 'iv' and x_eid = 300 then 1 end) as cnt_first_iv_s,
    sum(case when eid = 'iv' and x_eid = 300 then item_rnk end) as cnt_first_iv_s_rnk,
    sum(case when eid = 'iv' and x_eid = 2012 then 1 end) as cnt_first_iv_u2i,
    sum(case when eid = 'iv' and x_eid = 2012 then item_rnk end) as cnt_first_iv_u2i_rnk
from bs_first_click t
;
