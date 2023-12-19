select
    a.event_date
    ,contact as communication
    ,contact_type
    ,contact_id
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
    ,cm.microcat_id
    ,cm.category_id
    ,cl.location_id
    ,cm.vertical_id
    ,cm.vertical
    ,cm.logical_category_id
    ,cm.logical_category
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
	,cl.Logical_Level     
    ,coalesce(asd.is_asd, False) as is_asd
    ,asd.asd_user_group_id as asd_user_group_id
    ,coalesce(usm.user_segment_market, ls.segment) as user_segment_market
    ,lc.logical_param1_id
    ,lc.logical_param2_id
    ,coalesce(cpg.price_group, 'Undefined') as price_group
from dma.all_contacts a
left join dma.current_microcategories cm using (microcat_id)
left join dma.current_locations as cl on cl.location_id = a.location_id
left join dma.current_logical_categories lc on lc.logcat_id = cm.logcat_id
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
left join (
    select
        usm.user_id,
        usm.logical_category_id,
        usm.user_segment as user_segment_market,
        c.event_date
    from (
        select
            user_id,
            logical_category_id,
            user_segment,
            converting_date as from_date,
            lead(converting_date, 1, cast('2099-01-01' as date)) over(partition by user_id, logical_category_id order by converting_date) as to_date
        from DMA.user_segment_market
        where true
            and converting_date <= :last_date
    ) usm
    join dict.calendar c on c.event_date between :first_date and :last_date
    where c.event_date >= usm.from_date and c.event_date < usm.to_date
        and usm.to_date >= :first_date
) usm on a.seller_id = usm.user_id and cm.logical_category_id = usm.logical_category_id and cast(a.event_date as date) = usm.event_date  
left join (
    select item_id, price, actual_date from (
        select
            item_id, price, actual_date,
            row_number() over (partition by item_id order by actual_date desc) as rn
        from dds.S_Item_Price
        where item_id in (
            select distinct item_id
            from dma.click_stream_contacts
            where cast(eventdate as date) between :first_date and :last_date
                and item_id is not null
                -- and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
        )
    )t
    where rn = 1
) cif
    on a.item_id = cif.item_id
left join /*+jtype(h),distrib(l,a)*/ dict.current_price_groups cpg
    on   lc.logical_category_id = cpg.logical_category_id
    and  cif.price >= cpg.min_price
    and  cif.price <  cpg.max_price
where true 
    and cast(a.event_date as date) between :first_date and :last_date 