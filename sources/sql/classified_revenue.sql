with
am_client_day as (
    select
        amd.user_id,
        amd.active_from_date,
        amd.active_to_date,
        (amd.personal_manager_team is not null and amd.user_is_asd_recognised) as is_asd,
        amd.user_group_id,
        aug.group_name
    from DMA.am_client_day_versioned amd
    left join dict.asd_users_group aug on amd.user_group_id = aug.group_id
    where active_from_date::date <= :last_date
        and active_to_date::date >= :first_date
),
current_transaction_type as
(
    select transactiontype_id, transaction_type, transaction_subtype, product_type, product_subtype, IsRevenue as is_revenue, IsPayment as is_payment, is_classified
    from DMA.current_transaction_type ctt
),
condition as
(
    select value = 'Новое' as is_new, max(condition_id) as condition_id
    from dma.condition_values
    where value in ('Новое', 'Б/у')
    group by 1
)
select
    ur.user_id,
    ur.event_date,
    ur.location_id,
    nvl(condition.condition_id, 0) as condition_id, -- 0  = 'Undefined'
    l.LocationGroup_id as location_group_id,
    l.Logical_Level as location_level_id,
    l.Region as region,
    decode(l.level, 3, l.ParentLocation_id, l.Location_id) as region_id,
    l.RegionGeo as region_geo,
    l.RegionGroup as region_group,
    l.City as city,
    decode(l.level, 3, l.Location_id, null) as city_id,
    l.CityGeo as city_geo,
    l.City_Population_Group as city_population_group,
    ur.microcat_id,
    cm.category_name as category,
    cm.subcategory_name as subcategory,
    cm.param1,
    cm.param1_microcat_id as param1_id,
    cm.param2,
    cm.param2_microcat_id as param2_id,
    cm.param3,
    lc.vertical_id,
    lc.vertical,
    lc.logical_category_id,
    lc.logical_category,
    null as user_segment,
    nvl(usm.user_segment, ls.segment) as user_segment_market,
    nvl(aus.is_asd, False) as is_asd,
    nvl(aus.user_group_id, 8383) as asd_user_group_id,   -- By default is SS group - 8383
    aus.group_name as asd_group_name,
    ur.transactiontype_id,
    ctt.transaction_type,
    ctt.transaction_subtype,
    ctt.product_subtype,
    ctt.product_type,
    ctt.is_revenue,
    ctt.is_payment,
    ctt.is_classified,
    ur.transaction_amount,
    ur.transaction_amount_net,
    ur.transaction_amount_net_adj,
    ur.transaction_count,
    lc.logical_param1,
    lc.logical_param1_id,
    lc.logical_param2,
    lc.logical_param2_id,
    udc.user_id is not null as is_user_cpa,
	cpaaction_type,
	cpa_target_action_count
from DMA.paying_user_report ur
join current_transaction_type ctt using(transactiontype_id)

left join DMA.current_locations l on l.Location_id = ur.location_id and ur.location_id != -1

left join /*+jtype(h),distrib(l,a)*/ (
    select infmquery_id, logcat_id, microcat_id
    from infomodel.current_infmquery_category
    where infmquery_id in (
        select distinct infmquery_id
        from dma.paying_user_report
        where event_date::date between :first_date and :last_date
            and infmquery_id is not null
    )
) ci
    on ci.infmquery_id = ur.infmquery_id and ur.infmquery_id != -1

left join DMA.current_microcategories cm on cm.microcat_id = ci.microcat_id
left join dma.current_logical_categories lc on lc.logcat_id = ci.logcat_id

left join (
    select
        user_id,
        logical_category_id,
        user_segment,
        converting_date,
        lead(converting_date, 1, '20990101') over(partition by user_id, logical_category_id order by converting_date) as next_converting_date
    from DMA.user_segment_market
    where converting_date::date <= :last_date
) usm
    on  ur.user_id = usm.user_id
    and lc.logical_category_id = usm.logical_category_id
    and ur.event_date::date >= converting_date and ur.event_date::date < next_converting_date

left join am_client_day aus
	on aus.user_id = ur.user_id
	and ur.event_date between aus.active_from_date and aus.active_to_date

left join dict.segmentation_ranks ls
    on ls.logical_category_id=lc.logical_category_id
    and ls.is_default

left join (
    select event_date, user_id, max(cpaaction_type) as cpaaction_type
    from dma.user_day_cpa
    where event_date between :first_date and :last_date
    group by 1,2
) udc
    on ur.user_id = udc.user_id
    and ur.event_date = udc.event_date

left join condition using(is_new)

where ur.user_id not in (select cu.user_id from dma.current_user cu where cu.IsTest)
    and ur.event_date::date between :first_date and :last_date
