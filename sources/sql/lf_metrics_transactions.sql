with am_client_day as (
select user_id,
       active_from_date,
       active_to_date,
       (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
       user_group_id
from DMA.am_client_day_versioned
)
, user_segment_market as (
select 
    user_id, 
    logical_category_id, 
    user_segment, 
    timestampadd('s', 86399, converting_date::timestamp(0)) converting_date
from dma.user_segment_market
)
select 	lfmtr.first_vasfact_id, 
		lfmtr.second_vasfact_id, 
		lfmtr.user_id, 
		lfmtr.event_time::date event_date,
		lfmtr.tariff_source,
		case when lfmtr.lf_product = 'subscription 1.0' then 'subscription' else lfmtr.lf_product end tariff_type,
		lfmtr.lf_product_level tariff_subtype,
	    clc.vertical_id,
	    clc.vertical,
	    clc.logical_category_id,
	    clc.logical_category,
	    decode(cl.level, 3, cl.parentlocation_id, cl.location_id)    as region_id,
	    decode(cl.level, 3, cl.location_id, null)                    as city_id,
	    cl.locationgroup_id                                          as location_group_id,
	    cl.city_population_group                                     as population_group,
	    cl.logical_level                                             as location_level_id,
		pt.platform_id,
        tt.transaction_type,
        lfmtr.amount,
        lfmtr.amount_net,
        lfmtr.amount_net_adj,
        nvl(acd.is_asd, False)                                       as is_asd,
        acd.user_group_id                                            as asd_user_group_id,
		nvl(usm.user_segment, ls.segment) as user_segment_market
from dma.o_lf_metrics_transactions lfmtr
left join dds.h_platform pt 	
    on lower(lfmtr.avito_version) = lower(pt.external_id)
left join dma.current_pricecategories cp 	
    on lfmtr.pricecat_id = cp.pricecat_id
left join dma.current_logical_categories 	clc	
    on cp.logcat_id = clc.logcat_id
left join dma.current_locations       	cl 	
    on lfmtr.location_id = cl.location_id
left join dma.current_transaction_type	tt 	
    on lfmtr.first_transaction_type_id = tt.transactiontype_id
left join dict.segmentation_ranks ls 	
    on clc.logical_category_id = ls.logical_category_id 
    and is_default
left join user_segment_market usm 
    on lfmtr.user_id = usm.user_id 
    and clc.logical_category_id = usm.logical_category_id 
    and lfmtr.event_time interpolate previous value usm.converting_date
left join am_client_day acd
    on lfmtr.event_time::date between acd.active_from_date and acd.active_to_date
    and lfmtr.user_id = acd.user_id
where event_date::date between :first_date and :last_date
