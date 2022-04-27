create fact other_projects_revenue as
select
    t.amount_net_adj,
    t.observation_date,
    t.project_type,
    t.user_id
from dma.vo_other_projects_revenue t
;

create metrics other_projects_revenue as
select
    sum(case when project_type = 'advertisement' then amount_net_adj end) as advertisement_amount_net_adj,
    sum(case when project_type = 'autoteka' then amount_net_adj end) as autoteka_amount_net_adj,
    sum(case when project_type = 'advertisement_increased_for_rpm' then amount_net_adj end) as cnt_advertisement_amount_net_adj_increased_for_rpm,
    sum(case when project_type = 'domofond' then amount_net_adj end) as domofond_amount_net_adj
from other_projects_revenue t
;
