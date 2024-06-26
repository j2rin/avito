select
    cast(lineone_new_task_dttm as date) as event_date,
    user_id,
    item_id,
    selectdeal_id,
    'lead' as entity_type
from DMA.auto_select_crm_deal
where
    cast(lineone_new_task_dttm as date) between :first_date and :last_date
    and lineone_new_task_dttm is not null
union (
    select
        cast(deal_new_task_dttm as date) as event_date,
        user_id,
        item_id,
        selectdeal_id,
        'quality_lead' as entity_type
    from DMA.auto_select_crm_deal
    where
        cast(deal_new_task_dttm as date) between :first_date and :last_date
        and deal_new_task_dttm is not null
)
union (
    select
        cast(deal_booked_dttm as date) as event_date,
        user_id,
        item_id,
        selectdeal_id,
        'booking' as entity_type
    from DMA.auto_select_crm_deal
    where
        cast(deal_booked_dttm as date) between :first_date and :last_date
        and deal_booked_dttm is not null
)
union (
    select
        cast(deal_booked_tinkoff_dttm as date) as event_date,
        user_id,
        item_id,
        selectdeal_id,
        'booking_tinkoff' as entity_type
    from DMA.auto_select_crm_deal
    where
        cast(deal_booked_tinkoff_dttm as date) between :first_date and :last_date
        and deal_booked_tinkoff_dttm is not null
)
union (
    select
        cast(deal_success_dttm as date) as event_date,
        user_id,
        item_id,
        selectdeal_id,
        'deal' as entity_type
    from DMA.auto_select_crm_deal
    where
        cast(deal_success_dttm as date) between :first_date and :last_date
        and deal_success_dttm is not null
)
