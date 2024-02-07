with v_current_AbuseType as (
 SELECT t.AbuseType_id,
        t.Title,
        t.External_Id
 FROM ( SELECT h.AbuseType_id,
        sn.Title,
        h.External_ID AS External_Id,
        row_number() OVER (PARTITION BY h.AbuseType_id ORDER BY sn.Actual_date DESC) AS rnk
 FROM (DDS.H_AbuseType h LEFT  JOIN DDS.S_AbuseType_Title sn ON ((sn.AbuseType_id = h.AbuseType_id)))) t
 WHERE (t.rnk = 1)
)
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
    join v_current_AbuseType cat on cat.AbuseType_id = a.AbuseType_id
    join dma.current_microcategories cm on cm.microcat_id = a.microcat_id
where cast(abuse_date as date) between :first_date and :last_date
--     and abuse_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) --@trino
