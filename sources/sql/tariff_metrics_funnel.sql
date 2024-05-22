select
    tf.user_id,
    cast(tf.event_date as date) as event_date,
    pt.platform_id,
    cm.vertical_id          as vertical_id,
    cm.logical_category_id  as logical_category_id,
    cm.category_id          as category_id,
    cm.subcategory_id       as subcategory_id,
    cm.Param1_microcat_id   as param1_id,
    cm.Param2_microcat_id   as param2_id,
    cm.Param3_microcat_id   as param3_id,
    cm.Param4_microcat_id   as param4_id,
    tf.configurator_source,
    tf.step,
    tf.track_id,
    tf.event_no,
    coalesce(usm.user_segment, ls.segment) as user_segment_market,
    am.user_id is not null as is_asd
from 		dma.tariff_funnel 				tf
left join 	dds.h_platform 					pt 	on lower(tf.source_platform_name) = lower(pt.external_id)
left join 	dma.current_microcategories 	cm 	on tf.source_microcat_id = cm.microcat_id
left join (
    select user_id, event_date, user_is_asd_recognised
    from dma.am_client_day am
    where cast(am.event_date as date) between :first_date and :last_date
        -- and am.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
) am on tf.user_id = am.user_id and tf.event_date = am.event_date and am.user_is_asd_recognised

left join DMA.user_segment_market usm
    on  tf.user_id = usm.user_id
    and cm.logical_category_id = usm.logical_category_id
    and cast(tf.event_date as date) = usm.event_date
    and usm.reason_code is not null
    and usm.event_date between :first_date and :last_date
    -- and usm.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino

left join 	dict.segmentation_ranks 		ls 	on cm.logical_category_id = ls.logical_category_id and is_default
where cast(tf.event_date as date) between :first_date and :last_date
    -- and tf.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
