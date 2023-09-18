select     abuse_date,
           iu.user_id,
           cat.Title as abuse_type,
           platform_id,
           source,
           cm.category_id,
           cm.subcategory_id,
           cm.logcat_id as logical_category_id,
           cm.vertical_id
    from dma.current_abuses a
    join dds.l_item_user as iu on iu.item_id = a.item_id
    join dma.v_current_AbuseType cat on cat.AbuseType_id = a.AbuseType_id
    join dma.current_microcategories cm on cm.microcat_id = a.microcat_id
where cast(abuse_date as date) between :first_date and :last_date