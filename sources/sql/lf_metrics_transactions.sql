with am_client_day as (
    select user_id,
           active_from_date,
           active_to_date,
           (personal_manager_team is not null and user_is_asd_recognised) as is_asd,
           user_group_id
    from DMA.am_client_day_versioned
)
select 	lfmtr.first_vasfact_id,
		lfmtr.second_vasfact_id,
		lfmtr.user_id,
		cast(lfmtr.event_time as date) event_date,
		lfmtr.tariff_source,
		case when lfmtr.lf_product = 'subscription 1.0' then 'subscription' else lfmtr.lf_product end tariff_type,
		lfmtr.lf_product_level tariff_subtype,
	    clc.vertical_id,
	    clc.vertical,
	    clc.logical_category_id,
	    clc.logical_category,
        case cl.level when 3 then cl.ParentLocation_id else cl.Location_id end as region_id,
        case cl.level when 3 then cl.Location_id end                           as city_id,
	    cl.locationgroup_id                                          as location_group_id,
	    cl.city_population_group                                     as population_group,
	    cl.logical_level                                             as location_level_id,
		pt.platform_id,
        tt.transaction_type,
        lfmtr.amount,
        lfmtr.amount_net,
        lfmtr.amount_net_adj,
        coalesce(acd.is_asd, False)                                       as is_asd,
        acd.user_group_id                                            as asd_user_group_id,
		coalesce(usm.user_segment, ls.segment) as user_segment_market
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
    and ls.is_default
left join DMA.user_segment_market usm
    on  lfmtr.user_id = usm.user_id
    and clc.logical_category_id = usm.logical_category_id
    and cast(lfmtr.event_time as date) = usm.event_date
    and usm.event_date between :first_date and :last_date
    -- and usm.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
left join am_client_day acd
    on cast(lfmtr.event_time as date) between acd.active_from_date and acd.active_to_date
    and lfmtr.user_id = acd.user_id
where cast(lfmtr.event_time as date) between :first_date and :last_date
--     and lfmtr.event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
