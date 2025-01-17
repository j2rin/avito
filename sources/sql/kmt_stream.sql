select
    t.event_date,
    t.platform_id,
    t.cookie_id,
    t.user_id,
    t.session_hash,
    t.from_page,
    t.target_page,
    t.catalog_id,
    t.searches_kmt,
    t.item_views_kmt,
    t.contacts_kmt,
    t.item_views_serp_kmt,
    t.contacts_serp_kmt,
    t.contacts_in_session,
    t.item_views_in_session,
    t.session_duration,
    t.first_event,
    t.traffic_source,
    t.url_mask,
    t.searches_in_session,
  	t.microcat_id,
    cm.vertical_id,
    cm.logical_category_id,
    cm.category_id,
    cm.subcategory_id,
    cm.Param1_microcat_id   as param1_id,
    cm.Param2_microcat_id   as param2_id,
    cm.Param3_microcat_id   as param3_id,
    cm.Param4_microcat_id   as param4_id
from dma.kmt_stream t 
left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cm on cm.microcat_id = t.microcat_id
where cast(event_date as date) between :first_date and :last_date
    -- and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
