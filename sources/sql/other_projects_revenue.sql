select observation_date
    ,0  as user_id
    ,vertical_id
    ,project_type
    ,amount_net_adj
from dma.other_projects_revenue
where observation_date::date between :first_date and :last_date
