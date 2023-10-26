select  /*+syntactic_join*/
	ss.event_date,
	ss.platform_id,
	ss.cookie_id,
	ss.user_id,
	ss.adslot_id,
	ss.category_id,
	ss.subcategory_id,
	ss.microcat_id,
	cm.logical_category_id,
	cm.vertical_id,
	ss.dfp_group,
	ss.session_hash,
	ss.alid_id,
	ss.eventtype_ext,
	ss.cdtm,
	ss.min_cdtm,
	ss.reqnum,
	ss.max_reqnum,
	ss.business_platform,
	ss.site,
	ss.banner_code,
	ss.page_type,
	lower(ss.selling_system) as selling_system
from dma.ad_metric_funnel ss
left join /*+jtype(h),distrib(l,a)*/ dma.current_microcategories cm on cm.microcat_id = ss.microcat_id
where cast(ss.event_date as date) between :first_date and :last_date