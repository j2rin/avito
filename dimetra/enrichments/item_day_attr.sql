create enrichment item_day_attrs as select
    sia.start_time,
    sia.infmquery_id,
    sia.last_activation_time,
    sia.status_id,
    sia.vas_mask > 0 as                         is_vas,
    sia.is_user_cpa and sia.is_item_cpa as      is_cpx,
    sia.location_id,
    sia.item_user_id,
    sie.close_status_id,
    sie.close_reason_id
from :fact_table t
left join DMA.o_seller_item_active sia on sia.item_id = t.item_id
                                        and sia.event_date = t.__date__
left join DMA.o_seller_item_event sie on sie.item_id = t.item_id
                                        and sie.event_date = t.__date__
primary_key(__date__, item_id)