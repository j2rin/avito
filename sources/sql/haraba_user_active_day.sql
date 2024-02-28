select 
    entry_date,
    harabauser_id,
    user_id
from dma.haraba_user_active_day
where entry_date between :first_date and :last_date
--   and entry_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
      and user_id in (select user_id from dma.haraba_user 
                      where is_haraba_admin = false 
                            and shop_unbind_date is null 
                            and shop_id is null and is_deleted is null
                                --   and update_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
                                )