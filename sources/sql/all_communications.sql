select
    a.event_date
    ,contact as communication
    ,contact_type as communication_type
    ,contact_id as communication_id
    ,buyer_id
    ,seller_id
    ,caller_is_buyer
    ,reply_date
    ,reply_time_minutes
    ,a.item_id
    ,call_duration
    ,talk_duration
    ,is_common_funnel
    ,is_answered
    ,platform_id
    ,seller_platform_id
    ,buyer_cookie_id
    ,is_video_call
    ,coalesce(fancy.is_fancy, false)	as is_fancy
    ,coalesce(video.has_short_video, false)	as has_short_video
    ,cm.microcat_id
    ,cm.category_id
    ,cl.location_id
    ,lc.vertical_id
    ,lc.vertical
    ,lc.logical_category_id
    ,lc.logical_category
    ,cm.subcategory_id
    ,cm.Param1_microcat_id as param1_id 
    ,cm.Param2_microcat_id as param2_id
    ,cm.Param3_microcat_id as param3_id
    ,cm.Param4_microcat_id as param4_id
    ,is_target
    ,target_contact_type as type
    ,target_contact_tags as tags
    ,case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id
    ,case cl.level when 3 then cl.Location_id end                           as city_id
	,cl.LocationGroup_id                                          as location_group_id
	,cl.City_Population_Group                                     as population_group
    ,cl.Logical_Level                                            as location_level_id
    ,coalesce(asd.is_asd, False) as is_asd
    ,asd.asd_user_group_id as asd_user_group_id
    ,coalesce(usm.user_segment_market, ls.segment) as user_segment_market
    ,lc.logical_param1_id
    ,lc.logical_param2_id
    ,coalesce(cpg.price_group, 'Undefined') as price_group
    ,coalesce(a.condition_id, 0) as condition_id
from dma.all_contacts a
left join dma.current_microcategories cm on cm.microcat_id = a.microcat_id
left join dma.current_locations as cl on cl.location_id = a.location_id
left join /*+distrib(a,l)*/ (
    select infmquery_id, logcat_id
    from infomodel.current_infmquery_category
    where infmquery_id in (
        select distinct infmquery_id
        from dma.all_contacts
        where cast(event_date as date) between :first_date and :last_date
            and infmquery_id is not null
            -- and event_month between date_trunc('month', :first_date) and date_trunc('month', :last_date) -- @trino
    )
) ic
    on ic.infmquery_id = a.infmquery_id
left join dma.current_logical_categories lc on lc.logcat_id = ic.logcat_id
left join dict.segmentation_ranks ls on ls.logical_category_id = lc.logical_category_id and ls.is_default
left join (
    select
        asd.user_id,
        (asd.personal_manager_team is not null and asd.user_is_asd_recognised) as is_asd,
        asd.user_group_id as asd_user_group_id,
        asd.active_from_date,
        asd.active_to_date
    from DMA.am_client_day_versioned asd
    where true
        and asd.active_from_date <= :last_date
        and asd.active_to_date >= :first_date
) asd on a.seller_id = asd.user_id and cast(a.event_date as date) between asd.active_from_date and asd.active_to_date

left join /*+distrib(a,l)*/ (
    select user_id, logical_category_id, user_segment as user_segment_market, converting_date,
        lead(converting_date, 1, cast('2099-01-01' as date)) over(partition by user_id, logical_category_id order by converting_date) as next_converting_date
    from DMA.user_segment_market
    where converting_date <= :last_date
) as usm
    on a.seller_id = usm.user_id
    and cm.logical_category_id = usm.logical_category_id
    and cast(a.event_date as date) >= converting_date and cast(a.event_date as date) < next_converting_date

left join /*+distrib(a,l)*/ (
    select
        item_id,
        from_date,
        to_date,
  		price
    from dma.item_attr_log
    where item_id in (
            select distinct item_id
            from dma.all_contacts
            where cast(event_date as date) between :first_date and :last_date
                and item_id is not null
                -- and event_month between date_trunc('month', :first_date) and date_trunc('month', :last_date) -- @trino
        )
        and from_date <= :last_date
        and to_date >= :first_date
) cif
    on cif.item_id = a.item_id
    and cast(a.event_date as date) between cif.from_date and cif.to_date

left join dict.current_price_groups cpg
    on   lc.logical_category_id = cpg.logical_category_id
    and  cif.price >= cpg.min_price
    and  cif.price <  cpg.max_price
    
left join /*+distrib(a,l)*/
(
  select 
  	item_id,
  	is_fancy,
  	calc_date converting_date,
  	lead(calc_date, 1, cast('2099-01-01' as date)) over (partition by item_id order by calc_date) next_converting_date
  from dma.fancy_items
  where true
  	and calc_date <= :last_date
  -- and calc_year <= date_trunc('year', :last_date) -- @trino
) fancy on a.item_id = fancy.item_id and a.event_date >= fancy.converting_date and a.event_date < fancy.next_converting_date

left join 
(
  select 
    item_id,
    video is not null has_short_video,
    actual_date converting_date,
  	lead(actual_date, 1, cast('2099-01-01' as timestamp)) over (partition by item_id order by actual_date) next_converting_date
  from dds.s_item_video
  where true
  	and cast(actual_date as date) <= :last_date
) video on a.item_id = video.item_id and a.event_date >= video.converting_date and a.event_date < video.next_converting_date
  
where true 
    and cast(a.event_date as date) between :first_date and :last_date
    -- and event_month between date_trunc('month', :first_date) and date_trunc('month', :last_date) -- @trino
