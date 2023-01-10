create enrichment btc_birthday as
select
ubb.first_action_track_id is not null as new_user_btc
from :fact_table t
left join (
    select first_action_track_id as track_id, first_action_event_no as event_no
    from DMA.user_btc_birthday
    where first_action_event_date::date between :first_date::date and :last_date::date
        and action_type = 'btc'
) ubb on ubb.track_id = t.track_id and ubb.event_no = t.event_no
;