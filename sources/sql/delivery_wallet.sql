with /*+ENABLE_WITH_CLAUSE_MATERIALIZATION */ wallet_events  as (select  event_date,
        user_id,
        min(platform_id) as platfrom_id,
        count(distinct case when eventtype_ext = 6533 and has_avito_wallet = 1 then wcs.user_id end) as oneclick_load_users,
        count(case when eventtype_ext = 6533 and has_avito_wallet = 1 then wcs.user_id end) as oneclick_load_events,
        count(distinct case when eventtype_ext = 9673 then wcs.user_id end) wallet_banner_load_users,
        count(case when eventtype_ext = 9673 then wcs.user_id end)  wallet_banner_load_events,
        count(distinct case when eventtype_ext = 9676 then wcs.user_id end) as wallet_banner_click_users,
        count(case when eventtype_ext = 9676 then wcs.user_id end) wallet_banner_click_events,
        count(distinct case when eventtype_ext = 9058 then wcs.user_id end) as wallet_passcode_create_page_load_users,
        count(case when eventtype_ext = 9058 then wcs.user_id end) wallet_passcode_create_page_load_events,
        count(distinct case when eventtype_ext = 9063 then wcs.user_id end) as wallet_passcode_confirm_page_passcode_correct_users,
        count(case when eventtype_ext = 9063 then wcs.user_id end) wallet_passcode_confirm_page_passcode_correct_events,
        count(distinct case when eventtype_ext = 6567 and has_avito_wallet = 1 then wcs.user_id end) as oneclick_seen_users,
        count(case when eventtype_ext = 6567 and has_avito_wallet = 1 then wcs.user_id end) as oneclick_seen_events,
        count(distinct case when eventtype_ext = 6643 and payment_method_id = 8 then wcs.user_id end) as oneclick_choose_wallet_users,
        count(case when eventtype_ext = 6643 and payment_method_id = 8 then wcs.user_id end) as  oneclick_choose_wallet_events,
        count(distinct case when eventtype_ext = 6564 and payment_method_id = 8 then wcs.user_id end) as oneclick_pay_wallet_users,
        count(case when eventtype_ext = 6564 and payment_method_id = 8 then wcs.user_id end) as  oneclick_pay_wallet_events,
        count(distinct case when eventtype_ext = 8394  then wcs.user_id end) as wallet_phone_verification_page_render_users,
        count(case when eventtype_ext = 8394  then wcs.user_id end) as wallet_phone_verification_page_render_events,
        count(distinct case when eventtype_ext = 8401  then wcs.user_id end) as wallet_phone_verification_code_correct_users,
        count(case when eventtype_ext = 8401  then wcs.user_id end) as wallet_phone_verification_code_correct_events,
        count(distinct case when eventtype_ext = 8402  then wcs.user_id end) as wallet_phone_verification_code_sent_users,
        count(case when eventtype_ext = 8402  then wcs.user_id end) as wallet_phone_verification_code_sent_events,
        count(distinct case when eventtype_ext = 8416  then wcs.user_id end) as wallet_top_up_page_load_users, -- тут вероятно нужно выделить чекаут
        count(case when eventtype_ext = 8416  then wcs.user_id end) as wallet_top_up_page_load_events, --тут вероятно нужно выделить чекаут
        count(distinct case when eventtype_ext = 8421  then wcs.user_id end) as wallet_top_up_trx_create_users, -- тут вероятно нужно выделить чекаут
        count(case when eventtype_ext = 8421  then wcs.user_id end) as wallet_top_up_trx_create_events, --тут вероятно нужно выделить чекаут
        count(distinct case when eventtype_ext = 9665  then wcs.user_id end) as wallet_top_up_trx_success_users, -- тут вероятно нужно выделить чекаут
        count(case when eventtype_ext = 9665  then wcs.user_id end) as wallet_top_up_trx_success_events, --тут вероятно нужно выделить чекаут
        count(distinct case when eventtype_ext = 8415  then wcs.user_id end) as wallet_payment_trx_create_users, -- тут вероятно нужно выделить чекаут
        count(case when eventtype_ext = 8415  then wcs.user_id end) as wallet_payment_trx_create_events, --тут вероятно нужно выделить чекаут
        count(distinct case when eventtype_ext = 9877  then wcs.user_id end) as wallet_payment_trx_success_users, -- тут вероятно нужно выделить чекаут
        count(case when eventtype_ext = 9877  then wcs.user_id end) as wallet_payment_trx_success_events --тут вероятно нужно выделить чекаут
from dma.wallet_click_stream wcs
where cast(wcs.event_timestamp as date) > cast('2024-02-20' as date) and event_date between :first_date and :last_date
group by 1,2),
wallet_top_ups as (select ca.createdat as create_date,method,amount,user_id,
    row_number() over(partition by pdoci.PaymentDispatcherOperation_id, status order by actual_date asc) rn from
     dds.L_PaymentDispatcherOperation_ContainerInternal pdoci
    join  dds.L_PaymentDispatcherOperation_User  pdou  on  pdou.PaymentDispatcherOperation_id = pdoci.PaymentDispatcherOperation_id
  join  dds.S_PaymentDispatcherOperation_CreatedAt ca   on   ca.PaymentDispatcherOperation_id = pdoci.PaymentDispatcherOperation_id
   join dds.S_PaymentDispatcherOperation_Title    t    on   t.PaymentDispatcherOperation_id = pdoci.PaymentDispatcherOperation_id
    join dds.S_PaymentDispatcherOperation_Status s  on s.PaymentDispatcherOperation_id = pdoci.PaymentDispatcherOperation_id
  join  dds.S_PaymentDispatcherOperation_Method  m on      m.PaymentDispatcherOperation_id = pdoci.PaymentDispatcherOperation_id
   join dds.S_PaymentDispatcherOperation_Amount  a on     a.PaymentDispatcherOperation_id = pdoci.PaymentDispatcherOperation_id
   left join dds.S_PaymentDispatcherOperation_IsTwoStage   its  on   its.PaymentDispatcherOperation_id = pdoci.PaymentDispatcherOperation_id
   join dds.S_PaymentDispatcherOperation_Type     type on type.PaymentDispatcherOperation_id = pdoci.PaymentDispatcherOperation_id
  join  dds.S_ContainerInternal_Provider p  on p.ContainerInternal_id = pdoci.ContainerInternal_id
   join dds.S_ContainerInternal_IsDeal id    on id.ContainerInternal_id = pdoci.ContainerInternal_id
  join  dds.S_ContainerInternal_CreatedAt ca2 on  ca2.ContainerInternal_id = pdoci.ContainerInternal_id
  join dds.S_ContainerInternal_PaymentScenario ps on ps.ContainerInternal_id = pdoci.ContainerInternal_id
  where paymentscenario = 'wallet_top_up'
  and cast(ca.createdat as date) between :first_date and :last_date),
 top_ups as (
  select cast(create_Date as date) as event_date,
         user_id,
         sum(case when method like '%sbp%' then amount end) as sbp_top_up_amount,
         sum(case when method not like '%sbp%' then amount end) as card_top_up_amount,
         count(case when method like '%sbp%' then amount end) as sbp_top_up_count,
         count(case when method not like '%sbp%' then amount end) as card_top_up_count,
         sum(amount) as total_top_up_amount,
         count(amount) as total_top_up_count
      from wallet_top_ups
   where status = 'successful'
     and cast(create_Date as date) between  :first_date and :last_date
   and rn = 1
   group by 1,2)
select coalesce(we.user_id,tu.user_id) as user_id,
       coalesce(we.event_date,tu.event_date) as event_date,
       coalesce(we.platfrom_id,0) as platform_id,
        oneclick_load_users,
        oneclick_load_events,
        wallet_banner_load_users,
        wallet_banner_load_events,
        wallet_banner_click_users,
        wallet_banner_click_events,
        oneclick_seen_events,
        oneclick_seen_users,
        wallet_passcode_create_page_load_users,
        wallet_passcode_create_page_load_events,
        wallet_passcode_confirm_page_passcode_correct_users,
        wallet_passcode_confirm_page_passcode_correct_events,
        oneclick_choose_wallet_users,
        oneclick_choose_wallet_events,
        oneclick_pay_wallet_users,
        oneclick_pay_wallet_events,
        wallet_phone_verification_page_render_users,
        wallet_phone_verification_page_render_events,
        wallet_phone_verification_code_correct_users,
        wallet_phone_verification_code_correct_events,
        wallet_phone_verification_code_sent_users,
        wallet_phone_verification_code_sent_events,
        wallet_top_up_page_load_users,
        wallet_top_up_page_load_events,
        wallet_top_up_trx_create_users,
        wallet_top_up_trx_create_events,
        wallet_top_up_trx_success_users,
        wallet_top_up_trx_success_events,
        wallet_payment_trx_create_users,
        wallet_payment_trx_create_events,
        wallet_payment_trx_success_users,
        wallet_payment_trx_success_events,
        sbp_top_up_amount,
        card_top_up_amount,
        sbp_top_up_count,
        card_top_up_count,
        total_top_up_amount,
        tu.total_top_up_count
       ,case when cast(onboarding_ended_db as date) >= we.event_date then 'new_wallet_user'
            when cast(onboarding_ended_db as date) < we.event_date then 'old_wallet_user'
            else 'not_wallet_user' end as wallet_user_type
        from wallet_events we
left join /*+jtype(h),distrib(l,b)*/  top_ups tu on tu.event_date = we.event_date and we.user_id = tu.user_id
left join /*+jtype(h),distrib(l,b)*/  dma.current_wallet_user cwu on we.user_id = cwu.user_id




