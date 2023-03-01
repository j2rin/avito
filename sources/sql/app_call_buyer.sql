select
	AppCallStart::date as event_date,
    case when CallerIsBuyer then CallerDevice 		when not CallerIsBuyer then RecieverDevice 		end as cookie_id,
	case when CallerIsBuyer then AppCallCaller_id	when not CallerIsBuyer then AppCallReciever_id	end as user_id,
	case when CallerIsBuyer then CallerPlatform		when not CallerIsBuyer then RecieverPlatform 	end as platform_id,
	case when CallerIsBuyer then 'outgoing' when not CallerIsBuyer then 'incoming' end CallType,
    AppCallScenario,
    Reciever_MicAccess,
    Reciever_MicAccess_Changed,
    item_id,
    TalkDuration,
    ap.microcat_id,
    ap.location_id,
	-- Dimensions -----------------------------------------------------------------------------------------------------
    cm.vertical_id                                               as vertical_id,
    cm.logical_category_id                                       as logical_category_id,
    cm.category_id                                               as category_id,
    cm.subcategory_id                                            as subcategory_id,
    cm.Param1_microcat_id                                        as param1_id,
    cm.Param2_microcat_id                                        as param2_id,
    cm.Param3_microcat_id                                        as param3_id,
    cm.Param4_microcat_id                                        as param4_id,
    decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id)    as region_id,
    decode(cl.level, 3, cl.Location_id, null)                    as city_id,
    cl.LocationGroup_id                                          as location_group_id,
    cl.City_Population_Group                                     as population_group,
    cl.Logical_Level                                             as location_level_id
from dma.app_calls ap
left join DMA.current_microcategories cm on cm.microcat_id   = ap.microcat_id
left join DMA.current_locations       cl on cl.Location_id   = ap.location_id
where
		CallerIsBuyer is not null
	and AppCallScenario	is not null
    and AppCallStart::date between :first_date and :last_date
