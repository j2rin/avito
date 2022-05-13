create fact geo_loc_suggest as
select
    t.event_date::date as __date__,
    t.FromBlock,
    t.LocationInputLength,
    t.cookie_id as cookie,
    t.cookie_id,
    t.event_date,
    t.events,
    t.locationInput
from dma.vo_geo_loc_suggest t
;

create metrics geo_loc_suggest as
select
    sum(case when FromBlock = 1 then events end) as cnt_location_suggest_clicks,
    sum(case when FromBlock = 1 and locationInput is null then events end) as loc_suggest_clicks_null,
    sum(LocationInputLength) as loc_text_inputs_length,
    sum(case when LocationInputLength >= 0 then events end) as location_manual_text_inputs,
    sum(events) as location_text_inputs
from geo_loc_suggest t
;

create metrics geo_loc_suggest_cookie as
select
    sum(case when cnt_location_suggest_clicks > 0 then 1 end) as users_loc_suggest_clicks,
    sum(case when loc_suggest_clicks_null > 0 then 1 end) as users_loc_suggest_clicks_null,
    sum(case when location_manual_text_inputs > 0 then 1 end) as users_loc_suggest_manual_text_inputs
from (
    select
        cookie_id, cookie,
        sum(case when FromBlock = 1 then events end) as cnt_location_suggest_clicks,
        sum(case when FromBlock = 1 and locationInput is null then events end) as loc_suggest_clicks_null,
        sum(case when LocationInputLength >= 0 then events end) as location_manual_text_inputs
    from geo_loc_suggest t
    group by cookie_id, cookie
) _
;
