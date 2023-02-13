with
lf_users as (
    select distinct user_id
    from dma.o_lf_metrics
    where event_date::date between :first_date::date and :last_date::date
        and user_id is not null
),
usm as (
    select user_id, logical_category_id, user_segment, converting_date,
        lead(converting_date, 1, '20990101') over(partition by user_id, logical_category_id order by converting_date) as next_converting_date
    from DMA.user_segment_market
)
select /*+direct, syn_join*/
      olf.user_id
    , olf.event_date
    ----------------dimensions----------------
    , lf_product
    , lf_product_level
    , is_tariff_plus
	, subscriptionlog_id
    , is_cpa
    , tariff_source
    , nvl(acd.is_asd, False) as is_asd
    , acd.user_group_id      as asd_user_group_id
    , nvl(usm.user_segment, ls.segment) as user_segment_market
	, avito_version
    , lc.vertical
    , lc.vertical_id
    , lc.logical_category
    , lc.logical_category_id
    , decode(cl.level, 3, cl.parentlocation_id, cl.location_id) as region_id
    , olf.microcat_id
    , olf.location_id
    , olf.lf_product_level as tariff_subtype
    , case when olf.lf_product in ('subscription 1.0', 'subscription 2.0') then 'subscription' else olf.lf_product end as tariff_type
    , cl.locationgroup_id as location_group_id
    , decode(cl.level, 3, cl.location_id, null) as city_id
    , cl.city_population_group as population_group
    , cl.logical_level as location_level_id
    , lc.logical_param1_id
	, lc.logical_param2_id
    -----------------metrics-----------------
    , amount
	, amount_net
	, amount_tariff_package
	, amount_tariff_level
	, amount_tariff_package_net
	, amount_tariff_level_net
	, amount_net_adj
	, bonuses_in_amount
	, paid_activations_count
from dma.o_lf_metrics olf

left join /*+jtype(h),distrib(l,a)*/ (
    select infmquery_id, logcat_id
    from infomodel.current_infmquery_category
    where infmquery_id in (
        select distinct infmquery_id
        from dma.o_lf_metrics
        where event_date::date between :first_date and :last_date
            and infmquery_id is not null
    )
) ic
    on ic.infmquery_id = olf.infmquery_id

left join dma.current_logical_categories lc on lc.logcat_id = ic.logcat_id

left join /*+jtype(h),distrib(l,a)*/ DMA.current_microcategories cm
    on olf.microcat_id = cm.microcat_id

left join /*+jtype(h),distrib(l,b)*/ dict.segmentation_ranks ls
    on ls.logical_category_id = lc.logical_category_id
    and ls.is_default

left join /*+jtype(h),distrib(l,a)*/ (
    select
        usm.user_id,
        usm.logical_category_id,
        usm.user_segment,
        c.event_date
    from (
        select
            user_id,
            logical_category_id,
            user_segment,
            converting_date as from_date,
            lead(converting_date, 1, '20990101') over(partition by user_id, logical_category_id order by converting_date) as to_date
        from DMA.user_segment_market
        where true
            and user_id in (select user_id from lf_users)
            and converting_date <= :last_date::date
    ) usm
    join dict.calendar c on c.event_date between :first_date::date and :last_date::date
    where c.event_date >= usm.from_date and c.event_date < usm.to_date
        and usm.to_date >= :first_date::date
) usm
    on  olf.user_id = usm.user_id
    and olf.event_date = usm.event_date
    and lc.logical_category_id = usm.logical_category_id

left join /*+jtype(h),distrib(l,a)*/ dma.current_locations cl
    on olf.location_id = cl.location_id

left join /*+distrib(l,a)*/ (
   select
        asd.user_id,
        (asd.personal_manager_team is not null and asd.user_is_asd_recognised) as is_asd,
        asd.user_group_id as user_group_id,
        c.event_date
    from DMA.am_client_day_versioned asd
    join dict.calendar c on c.event_date between :first_date::date and :last_date::date
    where c.event_date between asd.active_to_date and asd.active_to_date
        and asd.active_from_date <= :last_date::date
        and asd.active_to_date >= :first_date::date
        and asd.user_id in (select user_id from lf_users)
) acd
    on olf.user_id = acd.user_id
    and olf.event_date::date = acd.event_date
where olf.event_date between :first_date and :last_date
