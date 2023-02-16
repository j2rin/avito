with  user_segment_market as (
    select
        user_id, logical_category_id, user_segment,
        timestampadd('s', 86399, converting_date::timestamp(0)) converting_date
    from dma.user_segment_market
)
select
    tf.user_id,
    tf.event_date::date event_date,
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
    nvl(usm.user_segment, ls.segment) as user_segment_market,
    am.user_id is not null as is_asd
from 		dma.tariff_funnel 				tf
left join 	dds.h_platform 					pt 	on lower(tf.source_platform_name) = lower(pt.external_id)
left join 	dma.current_microcategories 	cm 	on tf.source_microcat_id = cm.microcat_id
left join 	dma.am_client_day 				am 	on tf.user_id = am.user_id 	and tf.event_date = am.event_date and am.user_is_asd_recognised
left join 	user_segment_market 		    usm on tf.user_id = usm.user_id and cm.logical_category_id = usm.logical_category_id and tf.event_date interpolate previous value usm.converting_date
left join 	dict.segmentation_ranks 		ls 	on cm.logical_category_id = ls.logical_category_id and is_default
where tf.event_date::date between :first_date and :last_date
