select event_date,
       cookie_id,
       user_id,
       platform_id,
       is_buyer_autoteka as is_buyer_autoteka_30d,
       is_buyer_autoteka and date_diff('day', cast(buyer_autoteka_date as date), cast(event_date as date)) < 7 as is_buyer_autoteka_7d,
       is_buyer_autoteka and date_diff('day', cast(buyer_autoteka_date as date), cast(event_date as date)) < 1  as is_buyer_autoteka_1d,
       is_contact_autoteka as is_contact_autoteka_30d,
       is_contact_autoteka and date_diff('day', cast(contact_autoteka_date as date), cast(event_date as date)) < 7  as is_contact_autoteka_7d,
       is_contact_autoteka and date_diff('day', cast(contact_autoteka_date as date), cast(event_date as date)) < 1 as is_contact_autoteka_1d,
       24144500001 as logical_category_id,
       500012 as vertical_id
from dma.autoteka_buyers_share
where cast(event_date as date) between :first_date and :last_date
-- and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino