with /*+ENABLE_WITH_CLAUSE_MATERIALIZATION */
users as (
    select distinct user_id
    from dma.mnz_vas_seller_metrics
    where cast(event_date as date) between :first_date and :last_date
        and user_id is not null
        -- and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
)
select
	mv.event_date,
	mv.start_date,
	platform_id,
	mv.location_id,
	lc.vertical_id,
	cm.category_id,
	cm.subcategory_id,
	lc.logical_category_id,
	mv.user_id,
	product_type,
	product_subtype,
	transaction_type,
	transaction_subtype,
	isrevenue,
	ispayment,
	is_classified,
	amount,
	amount_net,
	transaction_counter,
	page_from,
	cm.Param1_microcat_id                                        as param1_id,
	cm.Param2_microcat_id                                        as param2_id,
	cm.Param3_microcat_id                                        as param3_id,
	cm.Param4_microcat_id                                        as param4_id,
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
	cl.LocationGroup_id                                          as location_group_id,
	cl.City_Population_Group                                     as population_group,
	cl.Logical_Level                                             as location_level_id,
    coalesce(acd.is_asd, False)                                       as is_asd,
    acd.user_group_id                                            as asd_user_group_id,
    coalesce(usm.user_segment, ls.segment)                            as user_segment_market
from dma.mnz_vas_seller_metrics mv
left join dma.current_microcategories cm on cm.microcat_id = mv.microcat_id
left join /*+jtype(h),distrib(l,a)*/ (
    select infmquery_id, logcat_id
    from infomodel.current_infmquery_category
    where infmquery_id in (
        select distinct infmquery_id
        from dma.mnz_vas_seller_metrics
        where cast(event_date as date) between :first_date and :last_date
            and infmquery_id is not null
            -- and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
    )
) ic
    on ic.infmquery_id = mv.infmquery_id
left join  dma.current_logical_categories lc on lc.logcat_id = ic.logcat_id
left join /*+jtype(h),distrib(l,b)*/ dict.segmentation_ranks ls on ls.logical_category_id = lc.logical_category_id and ls.is_default
left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations cl on cl.Location_id = mv.location_id
left join /*+jtype(h),distrib(l,a)*/ DMA.user_segment_market usm
    on mv.user_id = usm.user_id
    and lc.logical_category_id = usm.logical_category_id
    and mv.event_date = usm.event_date
    and usm.reason_code is not null
    and usm.event_date between :first_date and :last_date
    -- and usm.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
left join /*+jtype(h),distrib(l,a)*/ (
    select user_id,
           active_from_date,
           active_to_date,
           (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
           user_group_id
    from DMA.am_client_day_versioned
    where user_id in (select user_id from users)
) acd on mv.user_id = acd.user_id and mv.event_date between acd.active_from_date and acd.active_to_date
where cast(mv.event_date as date) between :first_date and :last_date
-- and mv.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
