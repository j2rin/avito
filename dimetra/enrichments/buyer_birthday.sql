create enrichment buyer_birthday as
select
    decode(t.__date__, bb.first_contact_event_date::date,true,false) as is_buyer_new
from :fact_table t
left join dma.buyer_birthday bb
    on   bb.cookie_id = t.cookie_id
    and  bb.logical_category_id = t.logical_category_id
primary_key(logical_category_id)
;