SELECT
    observation_date as event_date,
    observation_name,
    case when participant_type = 'visitor' then participant_id end as cookie_id,
    case when participant_type = 'user' 	 then participant_id end as user_id,
    participant_id,
    platform_id,
    mac.microcat_id,
    observation_value,
    session_no,
    -- Dimensions -----------------------------------------------------------------------------------------------------
    cm.vertical_id                                               as vertical_id,
    cm.logical_category_id                                       as logical_category_id,
    cm.category_id                                               as category_id,
    cm.subcategory_id                                            as subcategory_id,
    cm.Param1_microcat_id                                        as param1_id,
    cm.Param2_microcat_id                                        as param2_id,
    cm.Param3_microcat_id                                        as param3_id,
    cm.Param4_microcat_id                                        as param4_id
FROM dma.labor_metric_observation mac
LEFT JOIN /*+jtype(h)*/ DMA.current_microcategories cm on cm.microcat_id = mac.microcat_id
where cast(observation_date as date) between :first_date and :last_date
