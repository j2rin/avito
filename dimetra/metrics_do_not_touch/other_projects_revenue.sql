create fact other_projects_revenue as
select
    t.observation_date::date as __date__,
    *
from dma.vo_other_projects_revenue t
;

create metrics other_projects_revenue as
select
    sum(case when project_type in ('advertisement_direct', 'advertisement_indirect')  then amount_net_adj end) as advertisement_amount_net_adj,
    sum(case when project_type = 'autoteka' then amount_net_adj end) as autoteka_amount_net_adj,
    sum(case when project_type in ('advertisement_direct_increased_for_сpm', 'advertisement_indirect_increased_for_сpm') then amount_net_adj end) as cnt_advertisement_amount_net_adj_increased_for_rpm,
    sum(case when project_type = 'domofond' then amount_net_adj end) as domofond_amount_net_adj
from other_projects_revenue t
;
