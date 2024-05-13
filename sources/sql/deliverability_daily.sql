with /*+ENABLE_WITH_CLAUSE_MATERIALIZATION */
core_users as (
    select distinct user_id
    from dma.item_day_delivery idd
    where idd.event_date between cast(:first_date as date) and cast(:last_date as date)
        and user_id is not null
)
select /*+syntactic_join*/
    idd.event_date,
    idd.item_id,
    idd.user_id,
    bitwise_and(product_flag, bitwise_left_shift(cast(1 as bigint), 1)) > 0 as started_today,
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
    idd.available_pvz,
    idd.available_courierd2d,
    idd.available_locker,
    idd.available_courier,
    idd.available_dbs,
    idd.available_rdbs,
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
    (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 0 )) > 0) or (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 7 )) > 0) and coalesce(item_price, 0) between 10 and 150000 as available_pvz_pochta,
    (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 2 )) > 0) or (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 8 )) > 0) and coalesce(item_price, 0) between 10 and 150000 as available_pvz_bb,
    (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 3 )) > 0) or (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 9 )) > 0) and coalesce(item_price, 0) between 10 and 10000  as available_pvz_dpd,
    (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 4 )) > 0) or (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 10)) > 0) and coalesce(item_price, 0) between 10 and 150000 as available_pvz_exmail,
    (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 5 )) > 0) or (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 11)) > 0) and coalesce(item_price, 0) between 10 and 150000 as available_pvz_sbl,
    (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 6 )) > 0) or (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 12)) > 0) and coalesce(item_price, 0) between 10 and 80000  as available_pvz_cdek,
    (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 13)) > 0) or (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 30)) > 0) and coalesce(item_price, 0) between 10 and 50000  as available_courier_dostavista,
    (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 14)) > 0) or (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 31)) > 0) and coalesce(item_price, 0) between 10 and 50000  as available_courier_yandex,
    (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 16)) > 0) or (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 34)) > 0) and coalesce(item_price, 0) between 10 and 50000  as available_courierd2d_cse,
    (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 29)) > 0) or (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 32)) > 0) and coalesce(item_price, 0) between 10 and 150000 as available_courier_yandexcargo,
    (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 42)) > 0) and coalesce(item_price, 0) between 10 and 15000 as available_postamat_fivepost
from (
    select  event_date,
            item_id,
            user_id,
            flow,
            microcat_id,
            delivery_services_availability_flag,
            cpv_hash,
            product_flag,
            is_delivery_available_regular,
            is_delivery_active_regular,
            is_delivery_available_anydbs,
            is_delivery_active_anydbs,
            is_available_pvz,
            is_enabled_pvz,
            is_delivery_deleted,
            item_price,
            is_available_courier_d2d,
            is_enabled_courier_d2d,
            is_available_postamat,
            is_enabled_postamat,
            is_available_courier,
            is_enabled_courier,
            is_available_dbs,
            is_enabled_dbs,
            is_available_rdbs,
            is_enabled_rdbs,
            -- available flow
            is_available_pvz_c2c or is_available_pvz_b2c as available_pvz,
            is_available_courierd2d_c2c or (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 26)) > 0) as available_courierd2d,
            is_available_locker_c2c     or (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 25)) > 0) as available_locker,
            is_available_courier_c2c    or (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 24)) > 0) as available_courier,
            is_available_dbs_c2c        or (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 27)) > 0) as available_dbs,
            is_available_rdbs_c2c       or (bitwise_and(delivery_services_availability_flag, bitwise_left_shift(cast(1 as bigint), 28)) > 0) as available_rdbs
    from dma.item_day_delivery idd
) idd
inner join /*+jtype(h),distrib(l,a)*/ dma.current_microcategories cm on cm.microcat_id = idd.microcat_id
left join  /*+jtype(h)*/ DMA.user_segment_market usm
        on idd.user_id = usm.user_id
        and cm.logical_category_id = usm.logical_category_id
        and idd.event_date = usm.event_date
        and usm.reason_code is not null
        and usm.event_date between :first_date and :last_date
        -- and usm.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
left join dma.current_deliverycategories cdc on cdc.cpv_hash = idd.cpv_hash
left join dict.segmentation_ranks ls
    on ls.logical_category_id = cm.logical_category_id
    and ls.is_default
where idd.event_date between cast(:first_date as date) and cast(:last_date as date)
