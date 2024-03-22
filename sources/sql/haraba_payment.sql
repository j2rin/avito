select cast(create_date as date) as payment_date, amount, entity_id, user_id
from dma.haraba_payment hp
         left join dma.haraba_promocode hpr on hp.promocode_id = hpr.promocode_id
where true
  and state = 2
  and hp.type = 2
  and pay_type <> 4
  and coalesce(discount, 0) <> 100
  and user_id in (select user_id
                  from dma.haraba_user
                  where shop_id is null
                    and is_haraba_admin = false
                    and shop_unbind_date is null
                    --   and update_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
                    )
  and transaction_id not in (select processing_payment_id
                             from dma.haraba_payment
                             where type = 1000)