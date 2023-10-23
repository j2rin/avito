select
       bfe.launch_id,
       bfe.event_date,
       bfe.platform_id,
       bfe.platform,
       coalesce(cookie_id, 0) as cookie_id,
       bfe.user_id,
       bfe.microcat_id,
       bfe.eventtype_id,
       bfe.eventtype_ext,
       bfe.event_name_slug,
       bfe.broker_calc_data,
       bfe.client_side_app_version,
       bfe.is_human,
       bfe.location_id,
       bfe.region,
       bfe.from_page,
       bfe.credit_request_id,
       bfe.broker_bankside_id,
       bfe.is_issued,
       bfe.issued_date,
       bfe.is_closed,
       bfe.closed_date,
       bfe.credit_amount,
       bfe.bank_user_id,
       bfe.partner,
       bfe.bank_name,
       bfe.bank_platform_id,
       bfe.bank_platform,
       bfe.event_count,
       cm.vertical_id,
       cm.logical_category_id,
-- кооректировка from_page для авто кредитов
       case when event_name_slug = 'broker_credit_approved'
                     and from_page is null
                     and partner = 'tinkoff_direct' then 'tinkoff'
           when event_name_slug = 'broker_credit_approved'
                     and from_page is null
                     and partner = 'tinkoff_cash' then 'tinkoff_cash'
            when event_name_slug = 'broker_credit_approved'
                     and from_page is null
                     and partner in ('sravni_api', 'sravni_webview') then 'landing_sravni'
            when event_name_slug = 'broker_credit_approved'
                     and from_page is null
                     and partner is NULL and bank_name = 'Тинькофф Банк' then 'tinkoff'
            else from_page
            end as x_from_page,

       case when partner is null
                     and  bfe.event_date<=date('2021-05-13')
                     or partner = 'sravni_api' then 0.016*credit_amount
           when partner = 'tinkoff_direct'
                    and  bfe.event_date<=date('2021-06-20') then 0.02*credit_amount
           when partner = 'tinkoff_direct'
                    and  bfe.event_date>date('2021-06-20') then 0.023*credit_amount
           when partner = 'tinkoff_cash'
                    then 0.025*credit_amount
           else null
           end as revenue,
       case when is_issued = 1
                     and (closed_date<=date_trunc('month', issued_date) + interval'1'month + interval'4'day) then 1
           end as is_early_closed
from dma.broker_full_events bfe
    left join DMA.current_microcategories cm on cm.microcat_id=bfe.microcat_id
where cast(issued_date as date) between :first_date and :last_date
    -- and event_month between date_trunc('month', date(:first_date)) and date_trunc('month', date(:last_date))
    -- and event_month > date('2000-01-01') -- @trino
