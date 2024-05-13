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
    case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
    case cl.level when 3 then cl.Location_id end                           as city_id,
    cl.LocationGroup_id                                         as location_group_id,
    cl.City_Population_Group                                    as population_group,
    cl.Logical_Level                                            as location_level_id,
    cast(null as varchar) as user_segment,
    csc.user_id,
    lc.logical_param1_id,
    lc.logical_param2_id
from dma.click_stream_contacts csc

left join /*+jtype(h),distrib(l,a)*/ dma.current_microcategories cm
    on csc.microcat_id = cm.microcat_id
left join /*+jtype(h),distrib(l,a)*/ dma.current_locations cl
    ON  csc.Location_id = cl.location_id

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

left join (
    select cookie_id, logical_category_id, first_contact_event_date
    from dma.buyer_birthday
    where cookie_id in (
        select distinct cookie_id
        from dma.click_stream_contacts
        where cast(eventdate as date) between :first_date and :last_date
            and cookie_id is not null
            -- and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
    )
        -- and first_contact_event_year is not null -- @trino
) bb
    on   csc.cookie_id = bb.cookie_id
    and  lc.logical_category_id = bb.logical_category_id

left join DMA.user_segment_market usm
    on  csc.item_user_id = usm.user_id
    and lc.logical_category_id = usm.logical_category_id
    and csc.eventdate = usm.event_date
    and usm.reason_code is not null
    and usm.event_date between :first_date and :last_date
    -- and usm.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino

left join (
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

left join (
    select
        item_id,
        from_date,
        to_date,
  		price
    from dma.item_attr_log
    where item_id in (
            select distinct item_id
            from dma.click_stream_contacts
            where cast(eventdate as date) between :first_date and :last_date
                and item_id is not null
                -- and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
        )
        and from_date <= :last_date
        and to_date >= :first_date
) cif
    on cif.item_id = csc.item_id
    and cast(csc.eventdate as date) between cif.from_date and cif.to_date

left join /*+jtype(h),distrib(l,a)*/ dict.current_price_groups cpg
    on   lc.logical_category_id = cpg.logical_category_id
    and  cif.price >= cpg.min_price
    and  cif.price <  cpg.max_price

where csc.cookie_id is not null
    and csc.item_user_id not in (select user_id from dma."current_user" where istest)
    and cast(csc.eventdate as date) between :first_date and :last_date
    -- and event_year between date_trunc('year', date(:first_date)) and date_trunc('year', date(:last_date)) -- @trino
