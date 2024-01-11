select 
        event_timestamp,
        platform_id,
        platform,
        user_id,
        item_id,
        event_name_slug
from dma.installments_click_stream
where eventtype_ext in (4496, 4497, 4498, 4801, 7820, 7826, 7889)
        or eventtype_ext=7817 and installment_screen = 'success_verification'
        and event_date between :first_date and :last_date
        
union all 
        
select
        create_date as event_timestamp,
        cio.platform_id,
        external_id as platform,
        buyer_id as user_id,
        item_id,
        'installment_order_creation' as event_name_slug
from dma.current_installment_orders cio
left join dds.h_platform hp 
    on cio.platform_id = hp.platform_id
where cast(create_date as date) between :first_date and :last_date
    
union all 
        
select
        pay_date as event_timestamp,
        cio.platform_id,
        external_id as platform,
        buyer_id as user_id,
        item_id,
        'installment_order_payment' as event_name_slug
from dma.current_installment_orders cio
left join dds.h_platform hp 
    on cio.platform_id = hp.platform_id
where is_paid
        and cast(pay_date as date) between :first_date and :last_date