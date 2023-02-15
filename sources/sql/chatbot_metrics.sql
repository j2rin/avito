select 
    t.chat_id,
    flowrun_id,
    t.user_id,
    flow_id,
    start_flow_time::date,
    end_flow_time::date,
    reason_end_flow,
	0 as zero,
    case
        when flow_name like '%AUTO_REPLY%' then 'auto_reply'
        when flow_name like '%CPA%' or flow_name like '%Listing%'  then 'cpa'
        when flow_name like '%nd%' then 'new_developments'
        when flow_name like '%Support%' or flow_name like '%SS%' then 'support'
        when flow_name like  '%B2B%' then 'b2b'
        when flow_name like '%RE%' then 're'
        else 'other'
    end as group_name,
    transitions,
    datediff ('minute', t.start_flow_time, t.end_flow_time) as minute_end,
    split_part (t.chat_type,'_',1) as chat_type,
    case when t.chat_subtype = 'support' then true else false end is_support_chat,
    cm.vertical_id,
    cm.logical_category_id,
    cm.category_id,
    cm.subcategory_id
from  DMA.messenger_chat_flow_report t
left join dma.messenger_chat_report using (chat_id)
left join dma.current_microcategories cm using (microcat_id)
where (
        t.start_flow_time::date between :first_date and :last_date
        or t.end_flow_time::date between :first_date and :last_date
    )
    and not is_spam
    and not is_blocked
    and not is_deleted