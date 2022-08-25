create fact geo_laas_backend as
select
    t.event_date::date as __date__,
    *
from dma.vo_laas_stream t
;

create metrics geo_laas_backend as
select
    sum(1) as laas_requests,
    sum(case when laas_rule in ('coords_fallback', 'fallback', 'ip_fallback') then 1 end) as laas_requests_any_fallback_rule,
    sum(case when laas_rule in ('settings_choice', 'tooltip_choice') then 1 end) as laas_requests_any_manual_rule,
    sum(case when (coords_choice_rule = True or search_rule = True) then 1 end) as laas_requests_any_stack_rule,
    sum(case when laas_tooltip_type = 'change' then 1 end) as laas_requests_change,
    sum(case when location_level_id in (4, 5, 6) then 1 end) as laas_requests_city,
    sum(case when location_level_id in (4, 5, 6) and laas_tooltip_type = 'change' then 1 end) as laas_requests_city_change,
    sum(case when location_level_id in (4, 5, 6) and laas_tooltip_type = 'regular' then 1 end) as laas_requests_city_regular,
    sum(case when coords_choice_rule = True then 1 end) as laas_requests_coords_choice_rule,
    sum(case when laas_rule = 'coords_fallback' then 1 end) as laas_requests_coords_fallback_rule,
    sum(case when laas_rule = 'default' then 1 end) as laas_requests_default_rule,
    sum(case when laas_rule = 'fallback' then 1 end) as laas_requests_fallback_rule,
    sum(case when client_location_id is not null then 1 end) as laas_requests_has_client_location,
    sum(case when laas_rule = 'ip_fallback' then 1 end) as laas_requests_ip_fallback_rule,
    sum(case when location_level_id in (2, 3) then 1 end) as laas_requests_region,
    sum(case when location_level_id in (2, 3) and laas_tooltip_type = 'change' then 1 end) as laas_requests_region_change,
    sum(case when location_level_id in (2, 3) and laas_tooltip_type = 'regular' then 1 end) as laas_requests_region_regular,
    sum(case when laas_tooltip_type = 'regular' then 1 end) as laas_requests_regular,
    sum(case when location_level_id = 1 then 1 end) as laas_requests_russia,
    sum(case when location_level_id = 1 and laas_tooltip_type = 'change' then 1 end) as laas_requests_russia_change,
    sum(case when location_level_id = 1 and laas_tooltip_type = 'regular' then 1 end) as laas_requests_russia_regular,
    sum(case when search_rule = True then 1 end) as laas_requests_search_rule,
    sum(case when laas_rule = 'settings_choice' then 1 end) as laas_requests_settings_choice_rule,
    sum(case when laas_rule = 'tooltip_choice' then 1 end) as laas_requests_tooltip_choice_rule
from geo_laas_backend t
;

create metrics geo_laas_backend_cookie as
select
    sum(case when laas_requests_any_fallback_rule > 0 then 1 end) as user_laas_requests_any_fallback_rule,
    sum(case when laas_requests_any_manual_rule > 0 then 1 end) as user_laas_requests_any_manual_rule,
    sum(case when laas_requests_any_stack_rule > 0 then 1 end) as user_laas_requests_any_stack_rule,
    sum(case when laas_requests_default_rule > 0 then 1 end) as user_laas_requests_default_rule
from (
    select
        cookie_id,
        sum(case when laas_rule in ('coords_fallback', 'fallback', 'ip_fallback') then 1 end) as laas_requests_any_fallback_rule,
        sum(case when laas_rule in ('settings_choice', 'tooltip_choice') then 1 end) as laas_requests_any_manual_rule,
        sum(case when (coords_choice_rule = True or search_rule = True) then 1 end) as laas_requests_any_stack_rule,
        sum(case when laas_rule = 'default' then 1 end) as laas_requests_default_rule
    from geo_laas_backend t
    group by cookie_id
) _
;
