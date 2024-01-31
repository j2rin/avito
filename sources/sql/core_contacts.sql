with /*+ENABLE_WITH_CLAUSE_MATERIALIZATION */
users as (
    select distinct item_user_id as user_id
    from dma.click_stream_contacts
    where cast(eventdate as date) between :first_date and :last_date
        and item_user_id is not null
        -- and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
)
select /*+syntactic_join*/
    csc.item_id,
    cast(csc.eventdate as date) as event_date,
    csc.platform_id,
    csc.last_nondirect_session_source_id as traffic_source_id,
    csc.eventdate as action_dttm,
    item_user_id,
    ishuman_dev as is_human_dev,
    csc.microcat_id,
    csc.cookie_id,
    lc.vertical_id,
    lc.logical_category_id,
    cm.category_id,
    cm.subcategory_id,
    lc.logical_category,
    cm.param1_microcat_id as param1_id,
    coalesce(acd.is_asd, False)                                      as is_asd,
    -- По дефолту ставим SS сегмент - 8383
    coalesce(acd.user_group_id ,8383)                             as asd_user_group_id,
    cast(csc.eventdate as date) = cast(bb.first_contact_event_date as date) as is_buyer_new,
    coalesce(usm.user_segment, ls.segment)                           as user_segment_market,
    coalesce(cpg.price_group, 'Undefined')                      as price_group,
    csc.location_id,
    case coalesce(cl.level, cl_2.level) when 3 then coalesce(cl.ParentLocation_id, cl_2.ParentLocation_id) else coalesce(cl.Location_id, cl_2.Location_id) end as region_id,
    case coalesce(cl.level, cl_2.level) when 3 then coalesce(cl.Location_id, cl_2.Location_id) end as city_id,
    coalesce(cl.LocationGroup_id , cl_2.LocationGroup_id)                                  as location_group_id,
    coalesce(cl.City_Population_Group, cl_2.City_Population_Group)                         as population_group,
    coalesce(cl.Logical_Level, cl_2.Logical_Level)                                         as location_level_id,
    cast(null as varchar) as user_segment,
    csc.user_id,
    lc.logical_param1_id,
    lc.logical_param2_id
from dma.click_stream_contacts csc

left join /*+jtype(h),distrib(l,a)*/ dma.current_microcategories cm
    on csc.microcat_id = cm.microcat_id
left join /*+jtype(h),distrib(l,a)*/ dma.current_locations cl
    ON  csc.Location_id = cl.location_id
left join /*+jtype(h),distrib(l,a)*/ dma.current_locations cl_2
    ON  csc.Location_id = cl_2.location_id

left join /*+jtype(h),distrib(l,a)*/ (
    select infmquery_id, logcat_id
    from infomodel.current_infmquery_category
    where infmquery_id in (
        select distinct infmquery_id
        from dma.click_stream_contacts
        where cast(eventdate as date) between :first_date and :last_date
            and infmquery_id is not null
            -- and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
    )
) ic
    on ic.infmquery_id = csc.infmquery_id
left join /*+jtype(h),distrib(l,a)*/ dma.current_logical_categories lc
    on lc.logcat_id = ic.logcat_id
left join /*+jtype(h),distrib(l,a)*/ dict.segmentation_ranks ls
    on   ls.logical_category_id = lc.logical_category_id
    and  ls.is_default

left join /*+jtype(h),distrib(l,a)*/ (
    select cookie_id, logical_category_id, first_contact_event_date
    from dma.buyer_birthday
    where cookie_id in (
        select distinct cookie_id
        from dma.click_stream_contacts
        where cast(eventdate as date) between :first_date and :last_date
            and cookie_id is not null
            -- and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
    )
        -- and first_contact_event_year > date('2000-01-01') -- @trino
) bb
    on   csc.cookie_id = bb.cookie_id
    and  lc.logical_category_id = bb.logical_category_id

left join /*+jtype(h),distrib(l,a)*/ (
    select
        user_id,
        logical_category_id, user_segment,
        date_trunc('second', cast(converting_date as timestamp)) as converting_date,
        lead(converting_date, 1, cast('2099-01-01' as date)) over(partition by user_id, logical_category_id order by converting_date) as next_converting_date
    from DMA.user_segment_market
    where user_id in (select user_id from users)
) usm
    on  csc.item_user_id = usm.user_id
    and lc.logical_category_id = usm.logical_category_id
    and csc.eventdate >= usm.converting_date
    and csc.eventdate < usm.next_converting_date

left join /*+jtype(h),distrib(l,a)*/ (
    select user_id,
           active_from_date,
           active_to_date,
           (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
           user_group_id
    from DMA.am_client_day_versioned
    where user_id in (select user_id from users)
) acd
    on   acd.user_id = csc.item_user_id
    and  cast(csc.eventdate as date) between acd.active_from_date and acd.active_to_date

left join /*+jtype(h),distrib(l,a)*/ (
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
    on csc.item_id = cif.item_id

left join /*+jtype(h),distrib(l,a)*/ dict.current_price_groups cpg
    on   lc.logical_category_id = cpg.logical_category_id
    and  cif.price >= cpg.min_price
    and  cif.price <  cpg.max_price

where csc.cookie_id is not null
    and csc.item_user_id not in (select user_id from dma."current_user" where istest)
    and cast(csc.eventdate as date) between :first_date and :last_date
    -- and event_year between date_trunc('year', date(:first_date)) and date_trunc('year', date(:last_date)) -- @trino
