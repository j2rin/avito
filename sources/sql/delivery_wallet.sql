with /*+ENABLE_WITH_CLAUSE_MATERIALIZATION */ wallet_events  as (select
wcs.user_id,
platform_id,
has_avito_wallet,
payment_method_id,
eventtype_ext,
event_date,
 0 as amount,
'none' as method,
case when cast(onboarding_ended_db as date) >= wcs.event_date or onboarding_ended_db is null then 'new_wallet_user'
            when cast(onboarding_ended_db as date) < wcs.event_date then 'old_wallet_user'
            else 'not_wallet_user' end as wallet_user_type,
case when cast(onboarding_ended_db as date) <= wcs.event_date then true
            else false end as has_opened_delivery_wallet
from dma.wallet_click_stream wcs
left join /*+jtype(h)*/  dma.current_wallet_user cwu on wcs.user_id = cwu.user_id
where eventtype_ext in (6533, 9673, 9676, 9058, 9063, 6567, 6643, 6564, 8394, 8401, 8402, 8416, 8421, 9665, 8415, 9877) and
 cast(wcs.event_timestamp as date) > cast('2024-02-20' as date) and event_date between :first_date and :last_date --@trino
--     and event_year between date_trunc('year',:first_date) and date_trunc('year',:last_date) -- @trino
),
wallet_top_ups as (select ca.createdat as create_date,method,amount,user_id,status,pdoci.PaymentDispatcherOperation_id,
    row_number() over(partition by pdoci.PaymentDispatcherOperation_id, status order by actual_date asc) rn from
     dds.L_PaymentDispatcherOperation_ContainerInternal pdoci
    join /*+jtype(h)*/  dds.L_PaymentDispatcherOperation_User  pdou  on  pdou.PaymentDispatcherOperation_id = pdoci.PaymentDispatcherOperation_id
  join /*+jtype(h)*/  dds.S_PaymentDispatcherOperation_CreatedAt ca   on   ca.PaymentDispatcherOperation_id = pdoci.PaymentDispatcherOperation_id
   join  /*+jtype(h)*/dds.S_PaymentDispatcherOperation_Title    t    on   t.PaymentDispatcherOperation_id = pdoci.PaymentDispatcherOperation_id
    join /*+jtype(h)*/ dds.S_PaymentDispatcherOperation_Status s  on s.PaymentDispatcherOperation_id = pdoci.PaymentDispatcherOperation_id
  join /*+jtype(h)*/  dds.S_PaymentDispatcherOperation_Method  m on      m.PaymentDispatcherOperation_id = pdoci.PaymentDispatcherOperation_id
   join /*+jtype(h)*/ dds.S_PaymentDispatcherOperation_Amount  a on     a.PaymentDispatcherOperation_id = pdoci.PaymentDispatcherOperation_id
   left join /*+jtype(h)*/ dds.S_PaymentDispatcherOperation_IsTwoStage   its  on   its.PaymentDispatcherOperation_id = pdoci.PaymentDispatcherOperation_id
   join  /*+jtype(h)*/dds.S_PaymentDispatcherOperation_Type     type on type.PaymentDispatcherOperation_id = pdoci.PaymentDispatcherOperation_id
  join /*+jtype(h)*/  dds.S_ContainerInternal_Provider p  on p.ContainerInternal_id = pdoci.ContainerInternal_id
   join /*+jtype(h)*/ dds.S_ContainerInternal_IsDeal id    on id.ContainerInternal_id = pdoci.ContainerInternal_id
  join /*+jtype(h)*/  dds.S_ContainerInternal_CreatedAt ca2 on  ca2.ContainerInternal_id = pdoci.ContainerInternal_id
  join /*+jtype(h)*/ dds.S_ContainerInternal_PaymentScenario ps on ps.ContainerInternal_id = pdoci.ContainerInternal_id
  where paymentscenario = 'wallet_top_up'
  and cast(ca.createdat as date) between :first_date and :last_date),
 top_ups as (
  select
    wtu.user_id,
    0 as platform_id,
    0 as has_avito_wallet,
    8 as payment_method_id,
    0 eventtype_ext,
    cast(create_date as date) as event_date,
    amount,
    method,
    case when cast(onboarding_ended_db as date) >= cast(create_date as date) then 'new_wallet_user'
            when cast(onboarding_ended_db as date) < cast(create_date as date) then 'old_wallet_user'
            else 'not_wallet_user' end as wallet_user_type,
    case when cast(onboarding_ended_db as date) <= cast(create_date as date)  then true
            else false end as has_opened_delivery_wallet
      from wallet_top_ups wtu
      left join /*+jtype(h)*/  dma.current_wallet_user cwu on wtu.user_id = cwu.user_id
   where wtu.status = 'successful'
     and cast(create_Date as date) between  :first_date and :last_date
   and rn = 1)
 select *
 from wallet_events
 union
 select *
 from top_ups
