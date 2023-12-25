select  /*+syntactic_join*/
	track_id,
	event_no,
	event_date,
	event_timestamp,
	eid,
	platform_id,
	cast(cookie_id as bigint) as cookie_id,
	f.user_id,
	alid,
	profile_id,
	f.adv_campaign_id,
    adv_creative_id,
    s.loc_id as region_id,
    cm.logical_category_id,
    vertical_id,
    banner_code,
    item_id
from dma.profilepromo_funnel f
left join /*+jtype(h),distrib(l,a)*/ dma.profilepromo_campaigns c on c.adv_campaign_id = f.adv_campaign_id
left join /*+jtype(h),distrib(l,a)*/ dma.profilepromo_presets s on c.preset_id = s.preset_id
left join /*+jtype(h),distrib(l,a)*/ dma.current_logical_categories cm on cm.logical_category = s.logical_category
where cast(f.event_date as date) between :first_date and :last_date
	-- and f.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino