with /*+ENABLE_WITH_CLAUSE_MATERIALIZATION */
core_users as (
    select distinct user_id
    from dma.item_day_delivery idd
    where 1=1
        and idd.event_date::date between (:first_date)::date and (:last_date)::date
        and user_id is not null
)
select /*+syntactic_join*/
    idd.event_date,
    idd.item_id,
    idd.user_id,
    (product_flag&(1<<1)>0) as started_today,
    -- дименшены
    coalesce(usm.user_segment, ls.segment) as user_segment_market,
    idd.flow as deliverability_flow,
    cm.logical_category_id as logical_category_id,
    cdc.l2_node_id as delivery_category_id,
    cdc.l3_node_id as delivery_subcategory_id,
    cdc.l4_node_id as delivery_param1_id,
    cdc.l5_node_id as delivery_param2_id,
    cdc.l6_node_id as delivery_param3_id,
    cdc.l7_node_id as delivery_infomodel_param_id,
    cdc.l8_node_id as delivery_infomodel_param2_id,
    -- флаги и признаки
        -- общие
    is_delivery_available_regular,
    is_delivery_active_regular,
    is_delivery_available_anydbs,
    is_delivery_active_anydbs,
        -- available flow
    is_available_pvz_c2c or is_available_pvz_b2c as available_pvz,
    is_available_courierd2d_c2c or (delivery_services_availability_flag&(1<<26)>0) as available_courierd2d,
    is_available_locker_c2c or (delivery_services_availability_flag&(1<<25)>0) as available_locker,
    is_available_courier_c2c or (delivery_services_availability_flag&(1<<24)>0) as available_courier,
    is_available_dbs_c2c or (delivery_services_availability_flag&(1<<27)>0) as available_dbs,
    is_available_rdbs_c2c or (delivery_services_availability_flag&(1<<28)>0) as available_rdbs,
        -- enabled flow
    is_available_pvz and is_enabled_pvz and available_pvz
        and not coalesce(is_delivery_deleted, false) and coalesce(item_price, 0) between 10 and 150000 as is_enabled_pvz,
    is_available_courier_d2d and is_enabled_courier_d2d and available_courierd2d
        and not coalesce(is_delivery_deleted, false) and coalesce(item_price, 0) between 10 and 50000 as is_enabled_courierd2d,
    is_available_postamat and is_enabled_postamat and available_locker
        and not coalesce(is_delivery_deleted, false) and coalesce(item_price, 0) between 10 and 15000 as is_enabled_postamat,
    is_available_courier and is_enabled_courier and available_courier
        and not coalesce(is_delivery_deleted, false) and coalesce(item_price, 0) between 10 and 150000 as is_enabled_courier,
    is_available_dbs and is_enabled_dbs and available_dbs
        and not coalesce(is_delivery_deleted, false) and coalesce(item_price, 0) between 10 and 150000 as is_enabled_dbs,
    is_available_rdbs and is_enabled_rdbs and available_rdbs
        and not coalesce(is_delivery_deleted, false) and coalesce(item_price, 0) between 10 and 150000 as is_enabled_rdbs,
        -- available delivery service
    (delivery_services_availability_flag&(1<<0)>0) or (delivery_services_availability_flag&(1<<7)>0) and coalesce(item_price, 0) between 10 and 150000 as available_pvz_pochta,
    (delivery_services_availability_flag&(1<<2)>0) or (delivery_services_availability_flag&(1<<8)>0) and coalesce(item_price, 0) between 10 and 150000 as available_pvz_bb,
    (delivery_services_availability_flag&(1<<3)>0) or (delivery_services_availability_flag&(1<<9)>0) and coalesce(item_price, 0) between 10 and 10000 as available_pvz_dpd,
    (delivery_services_availability_flag&(1<<4)>0) or (delivery_services_availability_flag&(1<<10)>0) and coalesce(item_price, 0) between 10 and 150000 as available_pvz_exmail,
    (delivery_services_availability_flag&(1<<5)>0) or (delivery_services_availability_flag&(1<<11)>0) and coalesce(item_price, 0) between 10 and 150000 as available_pvz_sbl,
    (delivery_services_availability_flag&(1<<6)>0) or (delivery_services_availability_flag&(1<<12)>0) and coalesce(item_price, 0) between 10 and 80000 as available_pvz_cdek,
    (delivery_services_availability_flag&(1<<13)>0) or (delivery_services_availability_flag&(1<<30)>0) and coalesce(item_price, 0) between 10 and 50000 as available_courier_dostavista,
    (delivery_services_availability_flag&(1<<14)>0) or (delivery_services_availability_flag&(1<<31)>0) and coalesce(item_price, 0) between 10 and 50000 as available_courier_yandex,
    (delivery_services_availability_flag&(1<<16)>0) or (delivery_services_availability_flag&(1<<34)>0) and coalesce(item_price, 0) between 10 and 50000 as available_courierd2d_cse,
    (delivery_services_availability_flag&(1<<29)>0) or (delivery_services_availability_flag&(1<<32)>0) and coalesce(item_price, 0) between 10 and 150000 as available_courier_yandexcargo,
    (delivery_services_availability_flag&(1<<42)>0) and coalesce(item_price, 0) between 10 and 15000 as available_postamat_fivepost
from dma.item_day_delivery idd
inner join /*+jtype(h),distrib(l,a)*/ dma.current_microcategories cm on cm.microcat_id = idd.microcat_id
left join  /*+jtype(h),distrib(l,r)*/ (
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
                lead(converting_date, 1, cast('2099-01-01' as date)) over(partition by user_id, logical_category_id order by converting_date) as to_date
            from DMA.user_segment_market
            where true
                and user_id in (select user_id from core_users)
                and converting_date <= :last_date
        ) usm
        join dict.calendar c on c.event_date between :first_date and :last_date
        where 1=1
            and c.event_date >= usm.from_date
            and c.event_date < usm.to_date
            and usm.to_date >= :first_date
    ) usm on 1=1
        and idd.user_id = usm.user_id
        and idd.event_date = usm.event_date
        and cm.logical_category_id = usm.logical_category_id
left join dma.current_deliverycategories cdc on cdc.cpv_hash = idd.cpv_hash
left join dict.segmentation_ranks ls on 1=1
    and ls.logical_category_id = cm.logical_category_id
    and ls.is_default
where 1=1
    and idd.event_date::date between (:first_date)::date and (:last_date)::date