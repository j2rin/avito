select
    0 as user_id,
    ur.event_date,
    -- Для некоторых продуктов не указана вертикаль, укажем ее вручную
    case
        when ctt.product_type = 'auto_paid_contact'
            then 500012 --Transport
        when ctt.product_type = 'autoteka'
            then 500012 --Transport
        when ctt.product_type = 'JOB ChatBot'
            then 368340500002 --Vacancies
        when ctt.product_type = 'paid_contact'
            then 368294500001 --CVs
        else miq.vertical_id end vertical_id,
    ctt.transaction_type,
    ctt.transaction_subtype,
    ctt.product_subtype,
    ctt.product_type,
    ctt.is_classified,
    NULL as project_type,
    sum(ur.transaction_amount_net_adj) as amount_net_adj
from DMA.paying_user_report ur
    join DMA.current_transaction_type ctt on ctt.transactiontype_id = ur.transactiontype_id
        left join dma.current_microcategories miq on ur.microcat_id = miq.microcat_id
where ur.user_id not in (select cu.user_id from dma."current_user" cu where cu.IsTest)
    and ctt.IsRevenue
    and cast(ur.event_date as date) between :first_date and :last_date
    --and ur.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
group by 1,2,3,4,5,6,7,8
union all 
select 
    0 as user_id, 
    observation_date as event_date,
    vertical_id,
    NULL as transaction_type,
    NULL as transaction_subtype,
    NULL as product_subtype,
    NULL as product_type,
    false as is_classified,
    project_type,
    amount_net_adj
from dma.other_projects_revenue
where cast(observation_date as date) between :first_date and :last_date
union all
select
    0                                                       as user_id,
    cast(co.status_date as date)                            as status_date,
    clc.vertical_id                                         as vertical_id,
    NULL                                                    as transaction_type,
    NULL                                                    as transaction_subtype,
    NULL                                                    as product_subtype,
    NULL                                                    as product_type,
    false                                                   as is_classified,
    'delivery'                                              as project_type,
    coalesce(delivery_revenue_no_vat, 0) +
                    coalesce(seller_commission_no_vat, 0)   as delivery_amount_net_adj
from dma.delivery_metric_for_ab co
    left join dma.current_logical_categories clc
        on clc.logcat_id = co.logical_category_id
where is_accepted = True
    and cast(co.status_date as date) between date(:first_date) and date(:last_date)
    and status_year between date_trunc('year', date(:first_date)) and date_trunc('year', date(:last_date))
union all
select
    0                           as user_id,
    event_date,
    500012                      as vertical_id,
    NULL                        as transaction_type,
    NULL                        as transaction_subtype,
    NULL                        as product_subtype,
    NULL                        as product_type,
    false                       as is_classified,
    'auto_auction'              as project_type,
    amount_net_adj
from (select cast(terminated_at as date)        as event_date
                , sum(bt_revenue)       as amount_net_adj
      from dma.qd_auto_report_lots
      where has_buyout = 1
            and buyout_amount > 0
      group by cast(terminated_at as date)
      ) t
where cast(event_date as date) between :first_date and :last_date
