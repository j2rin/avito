select distinct delivery_service as value from dma.current_order where pay_date>=cast('2022-01-01' as date)
union all select 'other'