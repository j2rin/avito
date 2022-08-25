create fact advert_funnel as
select
    t.event_date::date as __date__,
    *
from dma.vo_advert_funnel t
;

create metrics advert_funnel as
select
    sum(case when eventtype_ext = 3215 then 1 end) as ad_clicks,
    sum(case when eventtype_ext = 3215 and banner_code in ('ads_mob_credit_btn', 'app', 'btni') then 1 end) as ad_clicks_credit,
    sum(case when eventtype_ext = 3215 and banner_code in ('ads_item_mob_top', 'ads_mob_low', 'item_atf_android', 'item_btf_android', 'item_btf_ios', 'item_mid', 'ldr_top', 'tgb2', 'wl') then 1 end) as ad_clicks_item,
    sum(case when eventtype_ext = 3215 and banner_code in ('desktop_mimicry', 'mobile_main', 'mobile_main_top', 'root_rnd_android', 'root_rnd_ios', 'root_top_android', 'root_top_ios', 'serp_low', 'serp_top') then 1 end) as ad_clicks_main,
    sum(case when eventtype_ext = 3215 and banner_code in ('messenger_ad_android', 'messenger_ad_ios') then 1 end) as ad_clicks_messenger,
    sum(case when eventtype_ext = 3215 and banner_code in ('ads_direct_low', 'ads_direct_top', 'ads_mob_central', 'ads_mob_mid', 'ads_mob_mid3', 'app_search_10', 'app_search_13', 'app_search_14', 'app_search_17', 'app_search_24', 'app_search_30', 'app_search_4', 'app_search_7', 'context_1', 'context_12', 'context_15', 'context_7', 'tile_1', 'tile_2') then 1 end) as ad_clicks_search,
    sum(case when eventtype_ext = 3250 then 1 end) as ad_fails,
    sum(case when eventtype_ext = 3215 and cdtm = min_cdtm then 1 end) as ads_clicks_for_time,
    sum(case when eventtype_ext = 3967 and reqnum = 1 then 1 end) as ads_full_inventory,
    sum(case when eventtype_ext = 3967 and reqnum = 1 and banner_code in ('ads_mob_credit_btn', 'app', 'btni') then 1 end) as ads_full_inventory_credit,
    sum(case when eventtype_ext = 3967 and reqnum = 1 and banner_code in ('ads_item_mob_top', 'ads_mob_low', 'item_atf_android', 'item_btf_android', 'item_btf_ios', 'item_mid', 'ldr_top', 'tgb2', 'wl') then 1 end) as ads_full_inventory_item,
    sum(case when eventtype_ext = 3967 and reqnum = 1 and banner_code in ('desktop_mimicry', 'mobile_main', 'mobile_main_top', 'root_rnd_android', 'root_rnd_ios', 'root_top_android', 'root_top_ios', 'serp_low', 'serp_top') then 1 end) as ads_full_inventory_main,
    sum(case when eventtype_ext = 3967 and reqnum = 1 and banner_code in ('messenger_ad_android', 'messenger_ad_ios') then 1 end) as ads_full_inventory_messenger,
    sum(case when eventtype_ext = 3967 and reqnum = 1 and banner_code in ('ads_direct_low', 'ads_direct_top', 'ads_mob_central', 'ads_mob_mid', 'ads_mob_mid3', 'app_search_10', 'app_search_13', 'app_search_14', 'app_search_17', 'app_search_24', 'app_search_30', 'app_search_4', 'app_search_7', 'context_1', 'context_12', 'context_15', 'context_7', 'tile_1', 'tile_2') then 1 end) as ads_full_inventory_search,
    sum(case when eventtype_ext = 3970 then 1 end) as ads_full_renders,
    sum(case when eventtype_ext = 3970 and banner_code in ('ads_mob_credit_btn', 'app', 'btni') then 1 end) as ads_full_renders_credit,
    sum(case when eventtype_ext = 3970 and banner_code in ('ads_item_mob_top', 'ads_mob_low', 'item_atf_android', 'item_btf_android', 'item_btf_ios', 'item_mid', 'ldr_top', 'tgb2', 'wl') then 1 end) as ads_full_renders_item,
    sum(case when eventtype_ext = 3970 and banner_code in ('desktop_mimicry', 'mobile_main', 'mobile_main_top', 'root_rnd_android', 'root_rnd_ios', 'root_top_android', 'root_top_ios', 'serp_low', 'serp_top') then 1 end) as ads_full_renders_main,
    sum(case when eventtype_ext = 3970 and banner_code in ('messenger_ad_android', 'messenger_ad_ios') then 1 end) as ads_full_renders_messenger,
    sum(case when eventtype_ext = 3970 and banner_code in ('ads_direct_low', 'ads_direct_top', 'ads_mob_central', 'ads_mob_mid', 'ads_mob_mid3', 'app_search_10', 'app_search_13', 'app_search_14', 'app_search_17', 'app_search_24', 'app_search_30', 'app_search_4', 'app_search_7', 'context_1', 'context_12', 'context_15', 'context_7', 'tile_1', 'tile_2') then 1 end) as ads_full_renders_search,
    sum(case when eventtype_ext = 3968 then 1 end) as ads_full_views,
    sum(case when eventtype_ext = 3968 and banner_code in ('ads_mob_credit_btn', 'app', 'btni') then 1 end) as ads_full_views_credit,
    sum(case when eventtype_ext = 3968 and banner_code in ('ads_item_mob_top', 'ads_mob_low', 'item_atf_android', 'item_btf_android', 'item_btf_ios', 'item_mid', 'ldr_top', 'tgb2', 'wl') then 1 end) as ads_full_views_item,
    sum(case when eventtype_ext = 3968 and banner_code in ('desktop_mimicry', 'mobile_main', 'mobile_main_top', 'root_rnd_android', 'root_rnd_ios', 'root_top_android', 'root_top_ios', 'serp_low', 'serp_top') then 1 end) as ads_full_views_main,
    sum(case when eventtype_ext = 3968 and banner_code in ('messenger_ad_android', 'messenger_ad_ios') then 1 end) as ads_full_views_messenger,
    sum(case when eventtype_ext = 3968 and banner_code in ('ads_direct_low', 'ads_direct_top', 'ads_mob_central', 'ads_mob_mid', 'ads_mob_mid3', 'app_search_10', 'app_search_13', 'app_search_14', 'app_search_17', 'app_search_24', 'app_search_30', 'app_search_4', 'app_search_7', 'context_1', 'context_12', 'context_15', 'context_7', 'tile_1', 'tile_2') then 1 end) as ads_full_views_search,
    sum(case when eventtype_ext = 3969 then 1 end) as ads_passbacks,
    sum(case when eventtype_ext = 3970 and cdtm = min_cdtm then 1 end) as ads_renders_for_time,
    sum(case when eventtype_ext = 3967 then 1 end) as ads_requests,
    sum(case when eventtype_ext = 3967 and banner_code in ('ads_mob_credit_btn', 'app', 'btni') then 1 end) as ads_requests_credit,
    sum(case when eventtype_ext = 3967 and cdtm = min_cdtm then 1 end) as ads_requests_for_time,
    sum(case when eventtype_ext = 3967 and banner_code in ('ads_item_mob_top', 'ads_mob_low', 'item_atf_android', 'item_btf_android', 'item_btf_ios', 'item_mid', 'ldr_top', 'tgb2', 'wl') then 1 end) as ads_requests_item,
    sum(case when eventtype_ext = 3967 and banner_code in ('desktop_mimicry', 'mobile_main', 'mobile_main_top', 'root_rnd_android', 'root_rnd_ios', 'root_top_android', 'root_top_ios', 'serp_low', 'serp_top') then 1 end) as ads_requests_main,
    sum(case when eventtype_ext = 3967 and reqnum = max_reqnum then 1 end) as ads_requests_max_num,
    sum(case when eventtype_ext = 3967 and banner_code in ('messenger_ad_android', 'messenger_ad_ios') then 1 end) as ads_requests_messenger,
    sum(case when eventtype_ext = 3967 and banner_code in ('ads_direct_low', 'ads_direct_top', 'ads_mob_central', 'ads_mob_mid', 'ads_mob_mid3', 'app_search_10', 'app_search_13', 'app_search_14', 'app_search_17', 'app_search_24', 'app_search_30', 'app_search_4', 'app_search_7', 'context_1', 'context_12', 'context_15', 'context_7', 'tile_1', 'tile_2') then 1 end) as ads_requests_search,
    sum(case when eventtype_ext = 3964 then 1 end) as ads_rmp_errors,
    sum(case when eventtype_ext = 3963 then 1 end) as ads_rmp_requests,
    sum(case when eventtype_ext = 3215 and cdtm = min_cdtm then cdtm end) as ads_sum_clicks_time,
    sum(case when eventtype_ext = 3970 and cdtm = min_cdtm then cdtm end) as ads_sum_renders_time,
    sum(case when eventtype_ext = 3967 and cdtm = min_cdtm then cdtm end) as ads_sum_requests_time,
    sum(case when eventtype_ext = 3968 and cdtm = min_cdtm then cdtm end) as ads_sum_views_time,
    sum(case when eventtype_ext = 3967 and reqnum = max_reqnum then reqnum end) as ads_sum_waterfall_depth,
    sum(case when eventtype_ext = 3968 and cdtm = min_cdtm then 1 end) as ads_views_for_time
from advert_funnel t
;

create metrics advert_funnel_alid_id as
select
    sum(case when ads_full_inventory > 0 then 1 end) as ads_inventory,
    sum(case when ads_full_inventory_credit > 0 then 1 end) as ads_inventory_credit,
    sum(case when ads_full_inventory_item > 0 then 1 end) as ads_inventory_item,
    sum(case when ads_full_inventory_main > 0 then 1 end) as ads_inventory_main,
    sum(case when ads_full_inventory_messenger > 0 then 1 end) as ads_inventory_messenger,
    sum(case when ads_full_inventory_search > 0 then 1 end) as ads_inventory_search,
    sum(case when ads_full_renders > 0 then 1 end) as ads_renders,
    sum(case when ads_full_renders_credit > 0 then 1 end) as ads_renders_credit,
    sum(case when ads_full_renders_item > 0 then 1 end) as ads_renders_item,
    sum(case when ads_full_renders_main > 0 then 1 end) as ads_renders_main,
    sum(case when ads_full_renders_messenger > 0 then 1 end) as ads_renders_messenger,
    sum(case when ads_full_renders_search > 0 then 1 end) as ads_renders_search,
    sum(case when ads_full_views > 0 then 1 end) as ads_views,
    sum(case when ads_full_views_credit > 0 then 1 end) as ads_views_credit,
    sum(case when ads_full_views_item > 0 then 1 end) as ads_views_item,
    sum(case when ads_full_views_main > 0 then 1 end) as ads_views_main,
    sum(case when ads_full_views_messenger > 0 then 1 end) as ads_views_messenger,
    sum(case when ads_full_views_search > 0 then 1 end) as ads_views_search
from (
    select
        cookie_id, alid_id,
        sum(case when eventtype_ext = 3967 and reqnum = 1 then 1 end) as ads_full_inventory,
        sum(case when eventtype_ext = 3967 and reqnum = 1 and banner_code in ('ads_mob_credit_btn', 'app', 'btni') then 1 end) as ads_full_inventory_credit,
        sum(case when eventtype_ext = 3967 and reqnum = 1 and banner_code in ('ads_item_mob_top', 'ads_mob_low', 'item_atf_android', 'item_btf_android', 'item_btf_ios', 'item_mid', 'ldr_top', 'tgb2', 'wl') then 1 end) as ads_full_inventory_item,
        sum(case when eventtype_ext = 3967 and reqnum = 1 and banner_code in ('desktop_mimicry', 'mobile_main', 'mobile_main_top', 'root_rnd_android', 'root_rnd_ios', 'root_top_android', 'root_top_ios', 'serp_low', 'serp_top') then 1 end) as ads_full_inventory_main,
        sum(case when eventtype_ext = 3967 and reqnum = 1 and banner_code in ('messenger_ad_android', 'messenger_ad_ios') then 1 end) as ads_full_inventory_messenger,
        sum(case when eventtype_ext = 3967 and reqnum = 1 and banner_code in ('ads_direct_low', 'ads_direct_top', 'ads_mob_central', 'ads_mob_mid', 'ads_mob_mid3', 'app_search_10', 'app_search_13', 'app_search_14', 'app_search_17', 'app_search_24', 'app_search_30', 'app_search_4', 'app_search_7', 'context_1', 'context_12', 'context_15', 'context_7', 'tile_1', 'tile_2') then 1 end) as ads_full_inventory_search,
        sum(case when eventtype_ext = 3970 then 1 end) as ads_full_renders,
        sum(case when eventtype_ext = 3970 and banner_code in ('ads_mob_credit_btn', 'app', 'btni') then 1 end) as ads_full_renders_credit,
        sum(case when eventtype_ext = 3970 and banner_code in ('ads_item_mob_top', 'ads_mob_low', 'item_atf_android', 'item_btf_android', 'item_btf_ios', 'item_mid', 'ldr_top', 'tgb2', 'wl') then 1 end) as ads_full_renders_item,
        sum(case when eventtype_ext = 3970 and banner_code in ('desktop_mimicry', 'mobile_main', 'mobile_main_top', 'root_rnd_android', 'root_rnd_ios', 'root_top_android', 'root_top_ios', 'serp_low', 'serp_top') then 1 end) as ads_full_renders_main,
        sum(case when eventtype_ext = 3970 and banner_code in ('messenger_ad_android', 'messenger_ad_ios') then 1 end) as ads_full_renders_messenger,
        sum(case when eventtype_ext = 3970 and banner_code in ('ads_direct_low', 'ads_direct_top', 'ads_mob_central', 'ads_mob_mid', 'ads_mob_mid3', 'app_search_10', 'app_search_13', 'app_search_14', 'app_search_17', 'app_search_24', 'app_search_30', 'app_search_4', 'app_search_7', 'context_1', 'context_12', 'context_15', 'context_7', 'tile_1', 'tile_2') then 1 end) as ads_full_renders_search,
        sum(case when eventtype_ext = 3968 then 1 end) as ads_full_views,
        sum(case when eventtype_ext = 3968 and banner_code in ('ads_mob_credit_btn', 'app', 'btni') then 1 end) as ads_full_views_credit,
        sum(case when eventtype_ext = 3968 and banner_code in ('ads_item_mob_top', 'ads_mob_low', 'item_atf_android', 'item_btf_android', 'item_btf_ios', 'item_mid', 'ldr_top', 'tgb2', 'wl') then 1 end) as ads_full_views_item,
        sum(case when eventtype_ext = 3968 and banner_code in ('desktop_mimicry', 'mobile_main', 'mobile_main_top', 'root_rnd_android', 'root_rnd_ios', 'root_top_android', 'root_top_ios', 'serp_low', 'serp_top') then 1 end) as ads_full_views_main,
        sum(case when eventtype_ext = 3968 and banner_code in ('messenger_ad_android', 'messenger_ad_ios') then 1 end) as ads_full_views_messenger,
        sum(case when eventtype_ext = 3968 and banner_code in ('ads_direct_low', 'ads_direct_top', 'ads_mob_central', 'ads_mob_mid', 'ads_mob_mid3', 'app_search_10', 'app_search_13', 'app_search_14', 'app_search_17', 'app_search_24', 'app_search_30', 'app_search_4', 'app_search_7', 'context_1', 'context_12', 'context_15', 'context_7', 'tile_1', 'tile_2') then 1 end) as ads_full_views_search
    from advert_funnel t
    group by cookie_id, alid_id
) _
;
