select distinct delivery_service as value from dma.current_order where pay_date>='2022-01-01'
union all select 'other'