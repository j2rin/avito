select 
    t.chat_id,
    t.user_id,
    t.flow_id,
    event_date::date,
    FlowTransition_id as flow_transition_id,
    eventtype_id,
    null as cnt_linkclicks
from  DMA.messenger_chatbot_events t
left join (select flow_id, name , row_number() over (partition by flow_id order by actual_date desc) rn from dds.S_Flow_Name) as fn 
    on t.flow_id = fn.flow_id and fn.rn = 1
where user_id not in (select user_id from dma.current_user where isTest)
and event_date::date between :first_date and :last_date
union all
select 
    chat_id,
    user_id,
    flow_id,
    start_flow_time::date as event_date,
    null as flow_transition_id,
    null as eventtype_id,
    cnt_linkclicks
from dma.messenger_chat_flow_report
where user_id not in (select user_id from dma.current_user where isTest)
and cnt_linkclicks>0
and start_flow_time::date between :first_date and :last_date


