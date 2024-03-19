select
      track_id,
      event_no,
      event_date,
      event_timestamp,
      eid,
      from_page,
      user_id,
      platform_id,
      ret.microcat_id,
      target_page,
      rfpid,
      offerid,
      chat_id,
      message_preview,
      flow_id,
      funnel_type,
      nsellers,
-- Dimensions -----------------------------------------------------------------------------------------------------
    ifnull(cm.category_id, ret.category_id)                      as category_id,
    cm.subcategory_id                                            as subcategory_id,
    cm.Param1_microcat_id                                        as param1_id,
    cm.Param2_microcat_id                                        as param2_id,
    cm.Param3_microcat_id                                        as param3_id,
    cm.Param4_microcat_id                                        as param4_id
from DMA.rfp_events_tracker ret
left join dma.current_microcategories cm on cm.microcat_id = ret.microcat_id
where true
    and date(event_date) between date(:first_date) and date(:last_date)
    -- and event_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino
