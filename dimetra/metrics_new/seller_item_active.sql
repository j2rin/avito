create fact seller_item_active as
select
    t.event_date::date as __date__,
    (t.start_time)::date AS start_date,
    (t.last_activation_time)::date AS last_activation_date,
    *
FROM DMA.o_seller_item_active t
participant_columns(user_id)
;
