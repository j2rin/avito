select     abuse_date,
           iu.user_id,
           cat.Title as abuse_type,
           p.external_id as platform,
           source,
           cm.category_name as category,
           cm.subcategory_name as subcategory,
           cm.logical_category,
           cm.vertical
    from dma.current_abuses a
    join dds.l_item_user as iu
    using(item_id)
    join dma.v_current_AbuseType cat on cat.AbuseType_id = a.AbuseType_id
    join dma.current_microcategories cm on cm.microcat_id = a.microcat_id
    left join dds.H_Platform p using(Platform_id)
where abuse_date::date between :first_date and :last_date