with /*+ENABLE_WITH_CLAUSE_MATERIALIZATION */
users as (
    select distinct user_id
    from dma.mnz_vas_seller_metrics
    where event_date::date between :first_date and :last_date
        and user_id is not null
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
	decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id)    as region_id,
	decode(cl.level, 3, cl.Location_id, null)                    as city_id,
	cl.LocationGroup_id                                          as location_group_id,
	cl.City_Population_Group                                     as population_group,
	cl.Logical_Level                                             as location_level_id,
    nvl(acd.is_asd, False)                                       as is_asd,
    acd.user_group_id                                            as asd_user_group_id,
    nvl(usm.user_segment, ls.segment)                            as user_segment_market
from dma.mnz_vas_seller_metrics mv
left join dma.current_microcategories cm on cm.microcat_id = mv.microcat_id

left join /*+jtype(h),distrib(l,a)*/ (
    select infmquery_id, logcat_id
    from infomodel.current_infmquery_category
    where infmquery_id in (
        select distinct infmquery_id
        from dma.mnz_vas_seller_metrics
        where event_date::date between :first_date and :last_date
            and infmquery_id is not null
    )
) ic
    on ic.infmquery_id = mv.infmquery_id

left join  dma.current_logical_categories lc on lc.logcat_id = ic.logcat_id
left join /*+jtype(h),distrib(l,b)*/ dict.segmentation_ranks ls on ls.logical_category_id = lc.logical_category_id and ls.is_default
left join /*+jtype(h),distrib(l,a)*/ DMA.current_locations cl on cl.Location_id = mv.location_id
left join /*+jtype(h),distrib(l,a)*/  (
    select user_id, logical_category_id, user_segment, converting_date,
        lead(converting_date, 1, '20990101') over(partition by user_id, logical_category_id order by converting_date) as next_converting_date
    from DMA.user_segment_market
    where user_id in (select user_id from users)
) usm
    on mv.user_id = usm.user_id
    and lc.logical_category_id = usm.logical_category_id
    and mv.event_date >= usm.converting_date and mv.event_date < usm.next_converting_date
left join /*+jtype(h),distrib(l,a)*/ (
    select user_id,
           active_from_date,
           active_to_date,
           (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
           user_group_id
    from DMA.am_client_day_versioned
    where user_id in (select user_id from users)
) acd on mv.user_id = acd.user_id and mv.event_date between acd.active_from_date and acd.active_to_date
where mv.event_date::date between :first_date and :last_date
